---
module: domain-media-feature-capture-relay
path: study/StudyVault/06-Media
keywords: media-api, presigned-upload, hls, dto-entity, mvvm
---

# GitHub #36 미디어 API와 업로드·릴레이 화면 연동

#module-media #module-capture #module-relay-cat #api-media #pattern-mvvm #test-media

## 원래 문제와 제약

미디어 도메인은 업로드 URL을 받은 뒤 실제 파일을 저장하고, 서버에 미디어 등록·수정 결과를 화면까지 전달해야 했다. 기존 임시 Client와 화면 흐름만으로는 PHOTO/VIDEO의 파일 전달, 서버 처리 상태, 릴레이 페이지 계약을 구분하기 어려웠다.

- 서버 응답 모델(DTO)과 화면 모델(Entity)을 분리한다.
- Entity는 서버 JSON 문자열을 직접 디코딩하지 않는다.
- Client closure의 기본 타입 인자는 `typealias ID`로 숨기지 않고 `_ id: String`처럼 명시한다.
- 사진·영상 원본 업로드와 영상 최종 재생(HLS)을 서로 다른 단계로 취급한다.
- 업로드 실패는 재시도 UI 없이 Alert만 표시하고, 촬영 원본 화면을 유지한다.
- 장소는 신규 촬영 화면에서 다시 수집하지 않고 `CaptureConfiguration.cat?.place`를 요청에 사용한다.

## 전체 흐름

```text
Capture / CatRegistration
  → FetchUploadURLRequestDTO
  → POST /media/upload-urls
  → PresignedUploadSource.data(JPEG) 또는 .file(video URL)
  → presigned URL에 PUT
  → POST /media 또는 PUT /media/{id}
  → READY: 즉시 완료
    PROCESSING: GET /media/{id}로 READY까지 대기
    FAILED/오류: loading 종료 + 실패 Alert
  → Feed에 READY Media 반영
```

영상의 presigned PUT은 원본 파일을 저장하는 단계다. 서버가 이 원본을 변환해 HLS(`.m3u8`)를 만들기 때문에 `.data`/`.file`은 HLS 재생 방식과 경쟁하는 선택지가 아니다. `.data`는 메모리에 있는 사진 원본, `.file`은 로컬 영상 파일이며 둘 다 서버 처리의 입력이다. 클라이언트는 `READY` 응답의 `mediaURL`만 HLS 재생에 사용한다.

## 책임 분리

| 계층 | 역할 | 대표 타입·파일 |
|---|---|---|
| Interface Entity | 화면에 필요한 의미와 상태 표현 | `Media`, `RelayCat`, `MediaType`, `ProcessingStatus` |
| Interface DTO | 서버 JSON의 필드·문자열·nullable 계약 표현 | `MediaResponseDTO`, `RelayCatResponseDTO`, 요청 DTO들 |
| Endpoint | path, method, query, body, 인증 여부 결정 | `MediaEndpoint` |
| Live Client | `NetworkClient` 호출 후 DTO를 Entity로 변환 | `MediaClient+Live` |
| Feature ViewModel | 업로드 순서, 상태 전이, 화면 callback 조정 | `CaptureViewModel`, `RelayCatViewModel` |
| View | Entity와 ViewModel state를 렌더링 | Capture, Feed, RelayCat 화면 |

DTO의 `toEntity()`가 `PHOTO`·`VIDEO`, `PROCESSING`·`READY`·`FAILED` 같은 서버 문자열을 도메인 타입으로 바꾼다. Entity에 `Codable`을 붙이면 화면 모델이 wire format에 다시 결합되므로 피한다.

## API 계약

| 동작 | HTTP | 경로 | 화면상 의미 |
|---|---|---|---|
| 업로드 URL 발급 | POST | `/media/upload-urls` | `catId`, media type으로 presigned URL 요청 |
| 미디어 등록 | POST | `/media` | PUT 완료 후 파일명·장소·댓글 등록 |
| 미디어 수정 | PUT | `/media/{id}` | 기존 미디어 원본 교체 및 정보 수정 |
| 미디어 조회 | GET | `/media/{id}` | VIDEO `PROCESSING` 상태 확인 |
| 좋아요 | PUT | `/media/{id}/like` | 릴레이 셀의 낙관적 좋아요 반영 |
| 릴레이 조회 | GET | `/media/relay` | anchor 및 앞·뒤 개수로 페이지 조회 |
| 미디어 삭제 | DELETE | `/media/{id}` | 릴레이 메뉴에서 삭제 |

`MediaEndpoint`가 인증 필요 여부를 공통으로 반환하며, 릴레이 조회는 `anchorId`, `catId`, `beforeCount`, `afterCount`를 query로 보낸다. `FetchUploadURLRequestDTO`와 등록 DTO의 nullable 필드는 `nil`이어도 서버 계약에 따라 JSON `null`을 명시할 수 있도록 custom `encode(to:)`를 사용한다. `encode`는 `Encodable`이 JSONEncoder에게 각 프로퍼티를 어떤 key와 값으로 직렬화할지 지시하는 메서드다. 자동 합성 인코딩으로 충분한 DTO는 custom 구현이 필요 없고, 명시적 `null`·key 변환·조건부 필드가 필요할 때만 사용한다.

## 사진과 영상 입력

`PresignedUploadSource`는 Entity가 아니라 Client 지원 모델이다.

| 소스 | 사용 시점 | Content-Type | 주의점 |
|---|---|---|---|
| `.data(Data)` | 카메라·앨범 사진 | `image/jpeg` | 원본을 JPEG Data로 정규화한 뒤 PUT |
| `.file(URL)` | 앨범·로컬 영상 | `video/mp4` | file URL만 허용하고 메모리 전체 로딩을 피함 |

앨범 영상 선택이 느렸던 이유는 전체 영상을 `Data`로 읽고 임시 파일로 다시 쓴 뒤 duration과 썸네일 12장을 생성했기 때문이다. `PickedVideo`의 `Transferable.FileRepresentation`은 영상을 파일 URL로 전달해 불필요한 메모리 변환을 줄인다. iCloud 원본 다운로드와 썸네일 생성 시간은 여전히 필요하다.

## 서버 처리 상태와 피드 반영

영상 등록 응답이 `PROCESSING`이면 원본 저장은 접수됐지만 HLS 변환이 끝나지 않은 상태다. CaptureViewModel은 `GET /media/{id}`를 일정 간격으로 조회하고 `READY`가 된 뒤 완료 callback을 호출한다.

```text
upload response PROCESSING
        ↓
fetchMedia(id)
  ├─ PROCESSING → 잠시 대기 후 재조회
  ├─ READY      → 완료 callback → Feed 반영
  └─ FAILED     → Alert, 촬영 결과 유지
```

제한 시간·횟수를 두어 무한 대기를 피한다. 별도 WebSocket·푸시가 도입되면 조회 대신 완료 이벤트 수신 후 단건 조회하는 방식으로 바꿀 수 있다.

## 장소 보존 규칙

신규 미디어의 장소는 `CaptureConfiguration.cat?.place`에서 가져온다. 등록 화면에서 고양이의 현재 장소를 정한 뒤 Capture로 이동하는 구조이기 때문이다. 릴레이 수정은 `RelayCat`의 id, name, place, imageURL로 `Cat`을 구성해 Capture에 전달하므로 기존 촬영 장소가 수정 요청에도 유지된다. CaptureConfirmView에는 장소 입력 UI를 추가하지 않는다.

## RelayCatCell 레이아웃 결정

```text
PHOTO: VStack
  photo area (remaining height, centered, scaledToFit)
  catInfo (content height)

VIDEO: ZStack(alignment: .bottomLeading)
  RelayVideo (fills cell)
  catInfo (overlaid on video)
```

사진은 `photoContent`에 `maxHeight: .infinity`를 유지하고 `.scaledToFit()`을 적용한다. 가로 사진이 위에 붙던 문제는 부모 `VStack`과 `catInfo` 내부의 `Spacer()`가 남은 공간을 나눠 가졌기 때문에 발생했다. 위치 조정은 `catInfo` 내부가 아니라 사진·영상의 부모 레이아웃이 맡는다.

릴레이 진입 직후 이미지가 잠깐 보였다가 검정으로 바뀐 현상은 새 presigned URL의 query string이 달라 `NZAsyncImage`의 task/cache key가 바뀌고 로딩 중 기존 이미지를 `nil`로 지웠기 때문이었다. 같은 미디어의 URL 갱신 중 기존 이미지를 유지하면 검정 전환을 피할 수 있다.

## 테스트·검증 포인트

- endpoint별 path, method, body, authorization과 릴레이 query 확인
- DTO nullable URL, `catId`, `place` 및 상태 문자열 변환 확인
- JPEG magic bytes와 `image/jpeg`, 영상 file URL과 `video/mp4` 확인
- URL 발급 → presigned PUT → 등록/수정 순서와 중복 실행 방지 확인
- `PROCESSING` 재조회 → `READY` 완료, `FAILED`/오류 Alert 전이 확인
- READY 전에는 피드에 영상을 넣지 않고 HLS URL은 READY 응답에서만 사용
- RelayCat place, anchor, cursor, 좋아요 실패 롤백, 삭제·수정 확인
- 가로·세로 사진의 scaledToFit 중앙 배치 및 영상 catInfo 오버레이 확인

## Related Notes

- [[고양이 API 연동 이슈38]]
- [[등록 API와 상태별 요청 계약]]
- [[보안 구성요소와 책임 경계]]
