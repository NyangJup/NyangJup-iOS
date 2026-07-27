# Capture·Feed 세션 회고 (2026-07-27)

이번 변경의 중심 문제는 피드에서 카메라를 여는 경로와 Capture 화면의 사진·영상 결과 흐름을 한 feature 계약으로 정리하는 것이었다. 동시에 공용 입력 컴포넌트와 SwiftUI 레이아웃을 다듬어 작은 iPhone에서도 컨트롤이 화면 밖으로 밀리지 않게 했다.

## 1. CircleButton과 Glass optional

`CircleButton`은 아이콘, 크기, 색상, 탭 동작을 공통화하면서 `glassEffect`를 선택적으로 주입하려고 했다. 그러나 `Glass`는 SwiftUI의 값 타입이고 modifier가 요구하는 타입과 optional(`Glass?`)은 그대로 맞지 않는다. 호출부에서 `.regular.interactive()`를 생략할 수 있게 만들려면 다음 중 하나가 필요하다.

- `glassEffect`를 필수로 받아 모든 호출부가 효과를 결정한다.
- `Glass?`를 받고 `if let`으로 modifier를 조건부 적용한다.
- 효과 유무를 별도 Boolean으로 두고 기본 효과를 내부에서 선택한다.

현재 피드의 플러스 버튼은 `.regular.interactive()`를 명시적으로 주입한다. 이 선택은 호출부가 시각 효과를 소유한다는 장점이 있지만, `CircleButton`의 실제 선언과 optional 처리 방식은 diff만으로 최종 의도를 완전히 확인하기 어렵다. 빌드 시 `Glass` modifier의 overload와 iOS 배포 타깃을 다시 확인한다.

## 2. Feed → Capture 표시 흐름

피드의 `plusButton`은 `FeedViewModel`에 `.plusButtonTapped`를 보내고 `state.isCameraPresented = true`로 바꾼다. `FeedView`는 이 상태를 `.fullScreenCover(isPresented:)`에 연결한다.

```text
플러스 탭
  → FeedViewModel.isCameraPresented = true
  → captureFactory.makeView(CaptureConfiguration, CaptureDelegate)
  → Capture 화면 표시
  → .complete 또는 .close
  → FeedViewModel.cameraDismissed
  → fullScreenCover 해제
```

완료 미디어를 당장 피드에서 소비하지 않는 현재 단계에서는 `.complete`와 `.close` 모두 카메라를 닫는다. 업로드나 피드 갱신을 연결할 때 `.complete(CapturedMedia)`의 데이터 전달을 별도 처리해야 한다.

## 3. Preview·Result 분리와 화면 비율

촬영 전 카메라 화면은 `CapturePreviewView`, 촬영 후 결과는 `CaptureResultView`가 맡는다. 결과 내부도 다음처럼 파일/컴포넌트를 분리했다.

| 역할 | 파일 | 입력 |
|---|---|---|
| 결과 라우팅 | `View/Result/CaptureResultView.swift` | `CapturedMedia.mode` |
| 사진 표시 | `CapturedPhotoView.swift` | 이미지 `Data` |
| 영상 표시·재생 | `CapturedVideoView.swift` | URL, trim 시간 Binding |

사진은 `CapturedMedia.data`, 영상은 `CapturedMedia.url`을 사용한다. 따라서 `CapturedMedia`를 하나의 결과 모델로 유지하되, 파일 단위 View는 매체별 실패 가능성(데이터/URL 없음)을 좁은 범위에서 처리한다.

화면 비율은 모드에 따라 `photo = 3 / 4`(4:3), `video = 9 / 16`(9:16)로 계산한다. 결과 상태에서는 `capturedMedia.mode`, 촬영 전에는 현재 `state.mode`를 기준으로 한다. 영상 결과의 trim 영역은 하단 바가 별도 공간을 예약하고, 미리보기 영상은 하단 컨트롤을 overlay로 겹치게 하는 것이 의도다. 즉 “영상 컨트롤이 떠 있다”와 “결과 영상이 trim UI 때문에 세로 공간을 덜 쓴다”는 서로 다른 레이아웃 정책이다.

## 4. VStack·Spacer·overlay와 기기별 레이아웃

초기 `VStack`에서 `Spacer`와 고정 비율 콘텐츠·컨트롤을 단순히 쌓으면 iPhone SE처럼 세로 공간이 부족할 때 하단 컨트롤이 화면 밖으로 밀릴 수 있다. `Spacer`는 남은 공간을 분배할 뿐 최소 높이를 보장하지 않으며, `aspectRatio` 콘텐츠와 고정 높이 버튼이 먼저 공간을 차지하면 음수에 가까운 여유가 생긴다.

현재 구조는 루트에 `GeometryReader`를 두고, 콘텐츠를 측정된 폭·높이에 맞춰 `.frame(...).clipped()`한다. 촬영 전 사진 모드에서는 `Spacer`를 두어 4:3 미리보기를 위쪽으로 밀고 컨트롤은 일반 VStack 공간을 예약한다. 영상 모드 컨트롤은 루트 `.overlay(alignment: .bottom)`로 올려 화면 하단에 고정한다. 결과 레이아웃은 영상/사진 콘텐츠 아래에 `CaptureResultBottomBar`를 실제로 배치해 trim 영역을 예약한다.

`GeometryReader`는 제안된 크기를 읽는 도구이지 자동으로 “화면에 맞춰 축소”하는 도구는 아니다. 따라서 작은 기기에서 확인할 때는 `aspectRatio`, 고정 컨트롤 높이, `layoutPriority`, `fixedSize(vertical:)`, `clipped`의 상호작용을 함께 본다. `fixedSize`는 컨트롤을 압축하지 않게 하지만 공간 부족 시 오히려 부모를 넘칠 수 있으므로, SE/14 시뮬레이터에서 실제 캡처가 필요하다.

## 5. 촬영 전환 지연과 PlayerRemoteXPC 로그

사진→영상 모드 전환 또는 녹화 시작·종료 직후의 지연은 SwiftUI Picker 자체보다 카메라 세션/AVFoundation 작업이 비동기로 진행되는 비용일 가능성이 높다. 영상 정지 후에는 `captureCompleted`에서 duration 로드와 썸네일 12개 생성을 순차적으로 시작하므로 결과 UI가 준비되기까지 추가 지연이 생긴다.

`PlayerRemoteXPC` 로그는 AVPlayer의 원격 플레이어 서비스와 관련된 진단 로그로 보이며, 로그가 출력된 사실만으로 앱 오류라고 단정하지 않는다. 저장소에는 해당 로그 원문·측정 시각이 없으므로, 다음을 분리 측정해야 한다.

1. 카메라 모드 변경 요청부터 실제 세션 전환 완료까지.
2. 녹화 종료부터 `CapturedMedia` 수신까지.
3. 영상 수신부터 trim duration/thumbnail 준비 완료까지.
4. `AVPlayer` 생성부터 첫 프레임 표시까지.

필요하면 signpost 또는 Instruments(AVFoundation/Time Profiler)로 위 구간을 측정하고, PlayerRemoteXPC 메시지는 재현 조건과 함께 기록한다.

## 6. SharedDesign 입력 컴포넌트 추출

기존 Home 전용 `CatNameTextField`, `CatSubmitButton`의 중복을 `SharedDesign`의 `NJTextField`, `NJButton`으로 옮겼다. 호출부가 다음 정책을 주입한다.

- `NJTextField`: `Binding<String>`, placeholder, `maxLength`; 글자 수 표시와 입력 길이 제한은 공통 구현.
- `NJButton`: 표시 문자열, 배경/전경 색상, enabled 여부, 탭 클로저.

GenerateCat과 CaptureConfirm이 같은 컴포넌트를 사용하므로 화면별 문구·최대 글자 수·색상은 각 View의 `Constant`에 남는다. 공용 컴포넌트가 feature 상태나 action enum을 알지 않게 한 것이 핵심 경계다.

## 7. 확인 Sheet의 모양과 한계

`CaptureConfirmView`는 `comment` Binding과 완료 클로저만 받고, `NJTextField`(최대 10자)와 비어 있지 않을 때만 활성화되는 `NJButton`을 배치한다. `.presentationDetents([.height(220)])`, `.presentationCornerRadius(28)`, `.presentationBackground(.white)`로 원하는 카드 모양을 시도했다.

SwiftUI 시스템 `.sheet`는 플랫폼이 폭·safe area·배경 합성 방식을 일부 결정한다. 따라서 콘텐츠에 흰 배경을 주어도 시스템 시트 전체 폭/뒤 배경까지 임의의 카드처럼 만들 수 있다는 보장은 없다. 더 강한 폭·배경 제어가 필요하면 커스텀 overlay 또는 별도 full-screen 컨테이너가 대안이지만, 현재 요구에는 시스템 sheet의 접근성과 단순성이 우선이다.

## 8. Capture 완료·닫기 아키텍처

기존 Capture 내부 Coordinator가 upload route를 push하던 구조를 제거하고, View가 의도만 ViewModel에 전달하도록 바꿨다.

```text
CaptureView 버튼
  → ViewModel.send(.view(...))
  → ViewModel이 사진/영상 완료 시점 판단
  → Factory가 onComplete/onClose를 CaptureDelegate.Action으로 변환
  → Feed가 delegate를 받아 cameraDismissed
```

- 사진: `completeButtonTapped`에서 즉시 `onComplete(media)` 호출.
- 영상: 확인 후 `VideoTrimClient.exportTrimmedVideo`가 끝난 뒤 `videoTrimExported`에서 완료 콜백 호출.
- 닫기: `closeButtonTapped`에서 `onClose()` 호출.

상태 이름은 `capturedMedia` 하나로 통일했다. 촬영 직후 원본 영상과 trim export 결과를 모두 화면 결과로 표현할 수 있고, export가 끝나면 같은 상태를 새 미디어로 교체한다. 별도 `completedMedia`를 두면 “현재 화면에 보이는 캡처”와 “외부로 보낼 최종 결과”가 이중화되어 동기화 규칙이 생긴다. 테스트의 output spy에만 `completedMedia`를 두어 외부 콜백 검증 용도로 사용하고, ViewModel 상태에서는 최종적으로 제거했다.

## 검증 명령과 남은 위험

- Capture/Home Swift Testing에서 플러스 표시 상태, 닫기 콜백, 사진 즉시 완료, 영상 export 완료를 확인한다.
- `swift test` 또는 Xcode 타깃 빌드로 `CircleButton`의 `Glass` optional 처리와 신규 파일 타깃 포함 여부를 확인한다.
- iPhone SE와 iPhone 14에서 사진/영상 촬영 전·후 레이아웃, sheet 높이, 영상 trim 영역을 직접 확인한다.
- 모드 전환·녹화·썸네일 생성 지연은 현재 정량 근거가 없고, PlayerRemoteXPC 로그 원문도 저장소에 없다. 재현 로그와 Instruments 측정이 후속 작업이다.
