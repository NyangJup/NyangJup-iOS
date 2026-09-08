# iOS 영상 업로드 아키텍처 학습 노트

> 현재 코드 기준의 영상 업로드 흐름을 정리한 노트다. 사진 업로드의 기존 흐름과 혼동하지 않도록, 이 문서의 중심은 `VideoUploadRequest` 경로다.

## 1. 문제와 책임 경계

영상은 촬영 직후 서버에 올릴 수 없다. 사용자가 선택한 구간을 먼저 잘라야 하고, 피드에 표시할 썸네일도 준비해야 한다. 동시에 Capture 화면이 네트워크 업로드까지 소유하면 화면 모듈이 피드 상태와 서버 등록 정책을 함께 알아야 한다.

핵심 질문은 “어디에서 무엇을 결정하고, 어느 모듈이 실패를 복구하는가?”였다.

| 관심사 | 선택지 | 현재 결론 | 수용한 트레이드오프 |
|---|---|---|---|
| Capture의 완료 이벤트 | Capture가 직접 업로드 / 요청만 전달 | `VideoUploadRequest`만 `onUpload`로 전달 | Capture는 단순해지지만 Feed가 업로드 오케스트레이션을 맡는다 |
| 영상 가공 위치 | Feed 또는 서버 / `CoreVideo` 로컬 처리 | `CoreVideoInterface.VideoTrimClient`가 trim·썸네일 담당 | 업로드 전 로컬 CPU·디스크 비용이 발생한다 |
| Feed의 즉시 표시 | 서버 응답까지 대기 / 임시 항목 삽입 | `UUID` 기반 placeholder 삽입 | 실패 시 임시 항목을 제거해야 한다 |
| 업로드 비동기 구조 | 별도 작업 객체·상태 머신 / ViewModel의 `Task` | 현재는 `Task { [weak self] in ... }` | 구현은 짧지만 취소·재시도 상태가 명시적이지 않다 |

## 2. 전체 흐름

```text
사용자 완료
   │
   ▼
CaptureViewModel
   └─ makeVideoUploadRequest()
       └─ CaptureDelegate.Action.upload(VideoUploadRequest)
           └─ FeedViewModel.videoUploadRequested(request)
               ├─ UUID 생성 + .uploading(UUID) 삽입
               └─ Task { [weak self] in
                   ├─ CoreVideo: exportTrimmedVideo(source, start, end)
                   ├─ CoreVideo: generateUploadThumbnail(source, start)
                   ├─ DomainMedia: uploadVideo(PreparedVideoUpload)
                   │   ├─ 업로드 URL 발급
                   │   ├─ video PUT
                   │   ├─ thumbnail PUT
                   │   └─ registerMedia + ready polling
                   └─ 성공: UUID 항목을 Media로 교체
                      실패: UUID 항목 제거 + 실패 Alert
```

## 3. Capture는 `VideoUploadRequest`만 보낸다

### 질문/우려

Capture가 영상 trim, 썸네일 생성, presigned URL 발급, 파일 업로드까지 직접 수행하면 화면 생명주기와 네트워크 책임이 강하게 결합된다. 반대로 Capture가 원본 URL과 사용자의 선택값만 넘기면, 사용자가 “완료”를 눌렀을 때 실제 업로드가 끝난 것은 아니다.

### 확인한 구현

`CaptureViewModel.completeCapture()`는 영상에 대해 `makeVideoUploadRequest(for:)`를 호출하고 `onUpload(request)`를 실행한다. 요청에는 다음 값만 담긴다.

- 원본 `sourceURL`
- `trimStartTime`, `trimEndTime`
- `catID`, `place`, `comment`

`CaptureDelegate.Action.upload(VideoUploadRequest)`와 `CaptureFactory+Live`의 `onUpload` 연결은 이 값을 Feed 쪽으로 전달한다. Capture에는 영상 업로드용 `MediaClient.uploadVideo` 호출이 없다. 사진은 별도의 Capture 내부 업로드 경로를 유지한다.

### 결론과 트레이드오프

Capture의 역할은 “촬영·선택·trim 범위 확정 및 업로드 요청 발행”으로 제한한다. 이 경계 덕분에 Capture를 서버 등록 정책과 독립적으로 테스트·재사용할 수 있다. 대신 완료 delegate를 받은 Feed가 업로드 실패, 임시 셀, 서버 처리 대기를 책임져야 한다.

## 4. Feed가 placeholder UI와 비동기 작업을 소유한다

### 질문/우려

서버 응답을 기다린 뒤 피드에 추가하면 사용자는 완료 버튼을 눌러도 아무 변화가 없다고 느낀다. 그러나 아직 `Media` ID가 없으므로 실제 셀을 만들 수도 없다.

### 현재 흐름

`FeedViewModel.videoUploadRequested`는 먼저 `UUID()`를 만들고 `state.items` 맨 앞에 `.uploading(uploadID)`를 삽입한다. `FeedItem`은 `.uploading(UUID)`와 `.media(Media)`를 구분하며, `UploadingFeedCell`은 회색 사각형과 `ProgressView`만 그린다. 따라서 아직 썸네일 URL이 없는 상태를 UI에서 안전하게 표현한다.

작업은 현재 별도 업로더 객체가 아니라 다음의 비구조적 `Task`로 시작한다.

```swift
Task { [weak self] in
    do { ... self?.send(.videoUploadCompleted(id: uploadID, media: media)) }
    catch { self?.send(.videoUploadFailed(id: uploadID)) }
}
```

성공 시 `uploadID`를 가진 항목만 찾아 `Media`로 교체한다. 실패 시 같은 ID의 placeholder를 제거하고 `showsUploadFailureAlert = true`로 바꾼다.

### 결론과 트레이드오프

Feed가 임시 상태와 화면 피드 반영을 함께 소유하는 것은 “요청 결과를 즉시 피드에 표현”하기에 단순하다. `UUID`를 매칭 키로 사용하므로 서버 미디어 ID가 생기기 전에도 안전하게 교체할 수 있다. 다만 현재 실패한 placeholder는 사라지고 전역 실패 Alert만 남으며, Feed 작업에는 진행률·자동 재시도·명시적 취소 UI가 없다. 여러 업로드를 동시에 시작할 수 있지만 작업 목록을 별도로 추적하지 않는다.

## 5. `CoreVideo`는 로컬 trim과 썸네일을 담당한다

`VideoTrimClient`는 네 가지 작업을 제공한다.

| API | 책임 |
|---|---|
| `loadDuration` | 원본 영상 길이 조회 |
| `generateThumbnails` | Capture trim bar에 보여 줄 프레임 배열 생성 |
| `exportTrimmedVideo` | 선택 구간을 H.264/AAC MP4 임시 파일로 내보냄 |
| `generateUploadThumbnail` | 선택 시작 시점의 JPEG `Data` 생성 |

Feed는 `exportTrimmedVideo` 결과 URL과 썸네일 Data를 `PreparedVideoUpload`로 묶어 DomainMedia에 넘긴다. 업로드가 끝나면 `defer`에서 임시 trimmed 파일을 삭제한다. 실제 인코딩은 `Task.detached`에서 수행되고 취소 시 reader/writer 취소로 이어진다.

이렇게 하면 원본 대신 완성된 구간만 전송하고 서버 계약을 단순하게 유지할 수 있다. 대신 큰 영상에서는 로컬 인코딩 시간·배터리·임시 저장 공간이 필요하다.

## 6. DomainMedia에서 `registerMedia`와 `uploadVideo`를 분리한 이유

`MediaClient`의 두 API는 이름이 비슷하지만 추상화 수준이 다르다.

| API | 입력 | 책임 |
|---|---|---|
| `registerMedia` | `UploadMediaRequestDTO` | 이미 저장소에 올라간 파일의 이름·타입·메타데이터를 백엔드에 등록 |
| `uploadVideo` | `PreparedVideoUpload` | 영상 URL 발급부터 video PUT, thumbnail PUT, `registerMedia`, processing 완료 polling까지의 영상 유스케이스 |

`MediaClient+Live.uploadVideo`는 video용 upload URL을 발급하고 trimmed file을 PUT한다. 썸네일 URL과 파일명이 없으면 실패하고, 썸네일 Data를 PUT한 뒤 `registerMedia`를 호출한다. 등록 응답이 `.processing`이면 최대 240회, 500ms 간격으로 조회하여 `.ready`가 될 때 반환한다. `.failed` 또는 timeout은 오류다.

`registerMedia`를 공개 primitive로 남긴 이유는 사진·기존 등록·테스트 mock에서 재사용하기 위해서다. 반면 `uploadVideo`에는 영상 순서를 캡슐화해 Feed가 presigned URL 순서와 DTO 조합을 알 필요가 없게 했다. 트레이드오프는 `uploadVideo`가 네트워크·저장소·processing polling까지 포함해 무거워졌다는 점이다.

## 7. ViewModel lifetime, `weak self`, UUID 교체

`FeedViewModel`은 `@MainActor @Observable` 객체다. 비동기 작업이 ViewModel을 강하게 캡처하면 화면이 사라져도 작업이 ViewModel 수명을 연장할 수 있으므로 `Task { [weak self] in ... }`를 사용한다. 작업이 끝났을 때 ViewModel이 이미 해제되었다면 `self?.send(...)`가 아무 동작도 하지 않는 것이 현재 의도다.

여기서 `UUID`는 네트워크의 media ID가 아니라 “이번 로컬 업로드 시도”의 식별자다.

```text
UUID A → placeholder A
성공(media-42) → placeholder A만 media-42로 교체
실패 → placeholder A만 제거
```

동시에 여러 업로드가 진행되어도 완료 순서와 무관하게 올바른 셀을 교체할 수 있다. 반면 `FeedViewModel`에는 Capture의 `uploadTask`처럼 업로드 작업을 보관·취소하는 프로퍼티가 없다. 화면이 사라진 뒤 작업의 명시적 취소나 백그라운드 지속 업로드는 보장되지 않는다.

## 8. 실패 동작과 검증 포인트

| 실패 지점 | 현재 결과 | 사용자 경험/리스크 |
|---|---|---|
| 로컬 trim·썸네일 생성 | `catch`로 이동 | placeholder 제거 후 실패 Alert; 로컬 재처리 재시도 버튼은 없음 |
| video 또는 thumbnail PUT | 동일 | 서버에 일부 객체만 남을 가능성과 재업로드 정책은 미정 |
| `registerMedia` | 동일 | 등록 전 실패는 서버 Media가 없으므로 placeholder만 제거 |
| processing `.failed`/timeout | 동일 | 등록은 됐을 수 있지만 Feed에서는 실패로 처리되어 orphan 정리 정책이 필요할 수 있음 |
| ViewModel 해제 | weak self nil | 결과를 UI에 반영하지 않음; 백그라운드 지속 업로드는 보장하지 않음 |

확인할 테스트 포인트는 다음과 같다.

1. trim 범위가 `exportTrimmedVideo`에 그대로 전달되는가.
2. 썸네일 생성 시점이 `trimStartTime`과 일치하는가.
3. `uploadVideo`가 video PUT → thumbnail PUT → `registerMedia` 순서를 지키는가.
4. 여러 `UUID` 업로드가 완료 순서와 무관하게 올바른 placeholder만 교체하는가.
5. 실패 시 해당 placeholder만 제거되고 다른 Feed 항목과 cursor는 보존되는가.

## 9. 소스 맵과 남은 TODO

| 영역 | 주요 파일 |
|---|---|
| 요청·Capture 경계 | `Projects/Feature/Capture/Interface/Sources/VideoUploadRequest.swift`, `CaptureDelegate.swift` |
| Capture 요청 발행 | `Projects/Feature/Capture/Sources/ViewModel/CaptureViewModel.swift` |
| Feed 상태·업로드 조정 | `Projects/Feature/Home/Sources/ViewModel/FeedViewModel.swift` |
| placeholder UI | `Projects/Feature/Home/Sources/Model/FeedItem.swift`, `View/Feed/UploadingFeedCell.swift`, `View/Feed/FeedList.swift` |
| 로컬 영상 처리 | `Projects/Core/Video/Interface/Sources/VideoTrimClient.swift`, `Projects/Core/Video/Sources/VideoTrimClient+Live.swift` |
| 미디어 API 경계 | `Projects/Domain/Media/Interface/Sources/Client/MediaClient.swift`, `Entity/PreparedVideoUpload.swift` |
| 실제 영상 업로드 | `Projects/Domain/Media/Sources/MediaClient+Live.swift` |

남은 결정은 Feed 작업의 명시적 취소·재시도, 앱 백그라운드 전환 중 지속 업로드, 부분 업로드 객체 정리, processing timeout 후 서버 상태 복구다. 이들은 현재 코드에서 해결된 사실이 아니라 후속 설계 과제다.

## Related Notes

- `study/capture-feed-session-2026-07-27.md`
- `study/feed-data-viewmodel.md`
- `study/core-network-hybrid.md`
