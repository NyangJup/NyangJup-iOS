# 사진 업로드 리사이징과 `UIGraphicsImageRenderer` 학습 노트

사진 업로드 지연과 피드 이미지 표시 지연을 줄이기 위해 iOS 업로드 직전에 사진을 정규화한 과정을 정리한다. 이 문서는 현재 코드 변경과 대화에서 확인된 결정·질문·트레이드오프를 구분해 기록한다.

## 1. 출발점: JPEG 품질만 낮추는 방식의 한계

기존 `CaptureViewModel.normalizedMedia(from:)`는 사진을 `UIImage`로 만든 뒤 다음처럼 JPEG 품질만 `0.9`로 바꿨다.

```swift
image.jpegData(compressionQuality: 0.9)
```

이 방식은 파일 압축률은 조정하지만 픽셀 크기는 줄이지 않는다. 예를 들어 4032×3024 사진은 여전히 4032×3024 픽셀인 채 업로드된다.

- 업로드 바이트가 커질 수 있다.
- 서버가 원본을 디코딩해 피드 썸네일을 만들 때 부담이 커진다.
- 상세 화면과 이미지 캐시에서 큰 픽셀 버퍼를 디코딩할 수 있다.
- JPEG 품질만 낮추면 사진 내용에 따라 용량 감소폭이 일정하지 않다.

따라서 이번 iOS 정책은 **픽셀 상한과 JPEG 품질을 함께 제한**하는 것이다.

## 2. 현재 정규화 정책

구현 위치: `Packages/Package/Projects/Feature/Capture/Sources/ViewModel/CaptureViewModel.swift`의 `normalizedMedia(from:)`

| 정책 | 값 | 의미 |
|---|---:|---|
| 긴 변 최대 크기 | 2048px | 큰 사진만 비율을 유지해 축소한다. |
| JPEG 품질 | 0.82 | 리사이즈 결과를 JPEG로 한 번 인코딩한다. |
| 작은 사진 | 업스케일하지 않음 | 2048px보다 작은 사진은 원래 픽셀 크기를 유지한다. |
| 영상 | 기존 흐름 유지 | `.photo`일 때만 정규화한다. |

### 계산 코드의 의미

```swift
let longestSide = max(image.size.width, image.size.height)
let ratio = min(photoMaximumPixelSize / longestSide, 1)
let targetSize = CGSize(
    width: max((image.size.width * ratio).rounded(), 1),
    height: max((image.size.height * ratio).rounded(), 1)
)
```

- `longestSide`: 가로·세로 중 긴 변을 기준으로 가로 사진과 세로 사진에 같은 규칙을 적용한다.
- `photoMaximumPixelSize / longestSide`: 긴 변을 2048px에 맞추는 축소 비율이다.
- `min(..., 1)`: 비율이 1보다 커지는 경우를 막아 작은 이미지를 업스케일하지 않는다.
- `targetSize`: 가로와 세로 모두 같은 `ratio`를 곱하므로 종횡비가 유지된다.
- `.rounded()`: 렌더링 크기를 정수로 만든다.
- `max(..., 1)`: 극단적인 입력에서도 한 변이 0이 되는 것을 막는다.

예를 들어 3000×1500 사진은 `ratio = 2048 / 3000`이 되어 2048×1024가 된다. 320×160 사진은 `ratio = 1`이 되어 320×160으로 남는다.

## 3. 왜 `UIGraphicsImageRenderer`를 사용했나

```swift
let format = UIGraphicsImageRendererFormat()
format.scale = 1
let normalizedImage = UIGraphicsImageRenderer(
    size: targetSize,
    format: format
).image { context in
    image.draw(in: CGRect(origin: .zero, size: targetSize))
}
```

리사이즈는 `UIImage.size` 숫자만 바꾸는 작업이 아니다. 목적 크기의 새 비트맵 버퍼를 만든 다음 원본 픽셀을 그 버퍼에 다시 샘플링해야 실제 픽셀 수가 줄어든다. 위 코드에서 renderer가 `targetSize` 크기의 새 캔버스를 만들고, `image.draw(in:)`가 원본을 그 캔버스의 사각형에 맞춰 그린다. 이 `draw`가 실제 리사이징이다.

`targetSize`를 원본과 같은 비율로 계산했기 때문에 새 캔버스 전체에 그려도 이미지가 찌그러지지 않는다. 캔버스의 비율이 원본과 다르면 전체 사각형에 맞추는 과정에서 왜곡이 발생한다.

### `scale = 1`의 의미

`UIGraphicsImageRenderer`의 크기는 포인트로 해석될 수 있고, 기기 화면 배율에 따라 실제 픽셀이 늘어날 수 있다. `format.scale = 1`을 명시하면 `targetSize`의 2048이 결과 이미지의 2048픽셀이 된다. 그렇지 않으면 Retina 기기의 2x·3x 배율 때문에 의도한 픽셀 상한이 흔들릴 수 있다.

### `opaque`와 배경 fill에 대한 현재 결정

대화에서 투명 PNG 처리를 위해 흰색을 채우는 방식은 일반 사진 업로드에 비해 과하다고 판단해 제거하기로 했다. 일반 카메라 JPEG처럼 입력이 불투명하다면 원본이 캔버스를 모두 덮으므로 흰색 fill은 필요하지 않다. 참고로 확인한 현재 diff에는 `format.opaque = true` 설정도 없으므로, `opaque`는 이번 코드가 실제로 적용한 설정이 아니라 투명 입력을 다룰 때 함께 검토해야 하는 개념이다.

현재 구현에서는 흰색 fill을 제거했다. 일반 카메라 JPEG처럼 입력이 불투명하면 원본이 캔버스를 모두 덮으므로 별도 배경 fill이 필요하지 않다. 투명 PNG도 선택할 수 있고 투명 영역을 JPEG로 변환해야 한다면 배경색을 명시하지 않을 때 검은색 등 예상하지 못한 색이 될 수 있다. 반대로 투명도를 보존해야 한다면 JPEG가 아니라 PNG 등 다른 출력 정책이 필요하다.

## 4. Core Graphics와의 관계

`UIGraphicsImageRenderer`는 Core Graphics와 별개의 리사이징 엔진이라기보다 UIKit이 Core Graphics 비트맵 컨텍스트 생성을 감싼 고수준 API다.

```text
UIGraphicsImageRenderer
  └─ bitmap CGContext와 출력 버퍼 생성
       └─ UIImage.draw(in:) 또는 CGContext.draw(...)
            └─ 목적 크기로 픽셀 재샘플링
```

예전에 직접 `CGContext`를 생성하고 `context.draw(cgImage, in:)`을 호출했다면 원리는 동일하다. 차이는 제어 수준과 코드량이다.

| 방법 | 장점 | 단점 |
|---|---|---|
| `UIGraphicsImageRenderer` | 코드가 짧고 UIKit 이미지 방향·출력 처리와 자연스럽게 연결된다. 이번처럼 한 곳에서 한 번 처리하기 쉽다. | 색 공간·픽셀 포맷·알파·보간을 세밀하게 통제하기 어렵고, `UIImage` 디코딩 뒤 새 버퍼를 만들 수 있다. |
| 직접 `CGContext` | 색 공간, 알파, 보간 품질, 픽셀 포맷을 세밀하게 제어할 수 있다. | 좌표계·상하 반전·bitmapInfo·이미지 방향을 직접 안전하게 처리해야 한다. 코드가 길어진다. |

즉, 현재 구현은 Core Graphics를 피한 것이 아니라 UIKit 쪽 래퍼를 사용해 실수 가능성과 변경량을 줄인 것이다.

## 5. 고려할 수 있었던 다른 대안

### ImageIO 다운샘플링

현재 입력이 `Data`이므로 `CGImageSourceCreateThumbnailAtIndex`와 `kCGImageSourceThumbnailMaxPixelSize`를 사용할 수 있다.

- 장점: 원본 전체를 큰 `UIImage`로 먼저 펼치지 않고 디코딩 단계에서 목표 픽셀로 줄일 수 있다. 큰 사진의 메모리 피크를 낮추는 데 유리하고 EXIF 방향 변환 옵션도 제공한다.
- 단점: `CGImageSource` 옵션과 Core Foundation 타입이 들어가 현재 코드보다 복잡하다. 최종 JPEG 재인코딩은 별도로 필요하다.

### Accelerate `vImage`

- 장점: 대량·고성능 CPU 이미지 처리와 명시적인 버퍼 제어에 적합하다.
- 단점: 단순 사진 한 장 업로드에는 API와 버퍼 관리가 과하다.

### Core Image

- 장점: 필터·색 보정·GPU 기반 처리 파이프라인과 결합하기 좋다.
- 단점: 단순 리사이즈만 필요할 때 의존성과 처리 흐름이 복잡해진다. 최종 인코딩과 메모리 정책도 별도로 결정해야 한다.

### 선택 결론

현재 요구사항은 “새 이미지 처리 타입을 만들지 않고 `normalizedMedia(from:)` 안에서 최대 크기와 품질만 적용”하는 것이었다. 그래서 `UIGraphicsImageRenderer`를 선택했다. UI 끊김이나 메모리 피크가 실제 측정에서 문제로 확인되면 직접 `CGContext`로 바꾸기보다 먼저 ImageIO 디코딩 단계 다운샘플링을 검토하는 것이 효과적이다. 직접 CGContext는 제어력은 늘지만 이 문제의 핵심인 원본 선 디코딩을 자동으로 해결하지 않는다.

## 6. 업로드 전체 흐름

```text
카메라/앨범 사진
   ↓
normalizedMedia(from:)
   ├─ 큰 사진: 긴 변 최대 2048px로 축소
   ├─ 작은 사진: 업스케일하지 않음
   └─ JPEG 품질 0.82로 한 번 인코딩
   ↓
기존 presigned URL 하나에 PUT 1회
   ↓
thumbnailFileName = nil인 사진 등록 요청
   ↓
서버가 원본에서 피드용 썸네일 생성
   ↓
피드: 썸네일 URL / 상세 화면: 원본 URL
```

iOS는 사진 원본과 썸네일을 두 번 올리지 않는다. 영상은 기존처럼 별도 썸네일 업로드 흐름을 유지한다. 이 선택은 iOS 업로드 구현을 단순하게 하지만, 서버가 사진 등록 시 썸네일을 동기 생성하는 책임과 처리 지연을 갖게 한다.

## 7. 테스트가 보장하는 내용

관련 테스트: `Packages/Package/Projects/Feature/Capture/Tests/FeatureCaptureTests.swift`

| 테스트/검증 | 보장 내용 |
|---|---|
| `photoUploadSourceNormalizesImageDataToJPEG` | 3000×1500 입력이 JPEG로 바뀌고 2048×1024로 축소되어 종횡비가 유지된다. |
| `photoUploadSourceDoesNotUpscaleSmallImage` | 320×160 입력이 320×160으로 남아 업스케일되지 않는다. |
| `completingPhotoWaitsForBothUploadRequests`의 사진 요청 검증 | 사진 등록 요청의 `thumbnailFileName`이 `nil`이고 presigned 사진 PUT이 1회다. |
| 기존 영상 테스트 | 영상 캡처·업로드 흐름이 사진 정규화 변경의 영향을 받지 않는다. |

현재 테스트는 크기·출력 형식·PUT 횟수를 검증한다. 실제 업로드 바이트 감소율, 여러 기기에서의 메모리 피크, 투명 PNG의 배경색, EXIF 방향이 모든 입력 형식에서 동일하게 처리되는지는 별도 측정·테스트 영역이다.

## 8. 결정과 남은 확인 사항

### 확인된 결정

- 별도 `PhotoUploadProcessor`, 새 Client, 새 Domain 타입을 만들지 않는다.
- 사진은 iOS에서 한 장만 업로드한다.
- 사진 썸네일은 서버가 생성한다.
- 현재 iOS 정책은 긴 변 2048px, JPEG 품질 0.82, 작은 사진 업스케일 금지다.

### 남은 위험과 후속 확인

- `UIImage(data:)`가 원본을 먼저 디코딩하므로 매우 큰 사진에서 메모리 피크가 생길 수 있다.
- 연속 촬영·저사양 기기에서 UI 끊김이 관찰되면 ImageIO 다운샘플링과 Instruments 측정을 우선 검토한다.
- 흰색 fill은 제거했으므로 투명 PNG를 지원할 필요가 생기면 배경색 정책을 별도로 결정한다.
- 0.82의 체감 화질과 실제 업로드 용량은 대표 사진 샘플로 측정해야 한다.
- EXIF 방향, 투명 PNG, 색 공간이 중요한 입력이면 별도 회귀 테스트를 추가한다.

## 관련 코드

- `Packages/Package/Projects/Feature/Capture/Sources/ViewModel/CaptureViewModel.swift`
- `Packages/Package/Projects/Feature/Capture/Tests/FeatureCaptureTests.swift`
- `Packages/Package/Projects/Domain/Media/Sources/MediaClient+Live.swift`
- `study/ImageLoader/03-Image-Downsampling.md`
- `study/ImageLoader/image-loader-sizing-and-preload.md`
