---
module: feature-relay-cat
path: study/StudyVault/05-Cats
keywords: swiftui, avplayer, lifecycle, relay-cat, audio
---

# 릴캣 삭제 후 이전 영상 소리가 남는 문제

## 문제와 제약

릴캣을 삭제하면 화면은 다음 영상으로 넘어가지만, 삭제된 영상의 소리가 계속 재생되는 현상이 있었다. 화면에 보이는 항목의 식별자(`currentItemId`)가 바뀌는 것과 기존 `AVPlayer`의 재생이 중단되는 것은 별개의 동작이라는 점이 핵심이었다.

이번 수정 범위는 삭제로 `RelayVideo` 뷰가 사라지는 경로에서 기존 플레이어의 재생 상태와 현재 아이템을 정리하는 것이다. 다른 영상 재생 흐름이나 삭제 API 계약은 변경하지 않는다.

## 결정 흐름

### 질문/우려

왜 다음 영상이 표시되는데 삭제한 영상의 오디오가 남는가?

### 고려한 선택지

1. 다음 영상의 `AVPlayer`를 재생하기만 한다.
2. 이전 플레이어를 `pause()`만 한다.
3. 뷰가 사라질 때 시간 관찰자를 제거하고, `pause()`한 뒤 `replaceCurrentItem(with: nil)`로 현재 미디어까지 비운다.

### 근거

기존 `onDisappear`는 `stopProgressObservation()`만 호출했다. 따라서 SwiftUI 뷰 계층에서 `RelayVideo`가 제거되어도 `@State`에 보관된 `AVPlayer`가 즉시 정지되거나 현재 `AVPlayerItem`을 해제한다는 보장이 없었다. 실제 변경된 `RelayVideo`는 다음 순서로 정리한다.

```swift
.onDisappear {
    stopProgressObservation()
    player.pause()
    player.replaceCurrentItem(with: nil)
}
```

### 결론

삭제로 영상 뷰가 사라지는 시점을 플레이어 정리 지점으로 사용한다. 관찰자를 먼저 제거한 뒤 재생을 멈추고, `replaceCurrentItem(with: nil)`로 삭제된 영상의 `AVPlayerItem`을 명시적으로 분리한다.

### 받아들인 트레이드오프

- `onDisappear`는 “삭제”뿐 아니라 다른 화면 전환 등 뷰가 사라지는 모든 경로에서 호출될 수 있다. 이 경우에도 이전 영상의 오디오가 남지 않는 것이 의도된 안전한 동작이다.
- `replaceCurrentItem(with: nil)` 뒤 같은 `RelayVideo` 인스턴스를 재사용해 재생을 재개하는 흐름은 전제하지 않는다. 새 영상은 새 뷰/새 플레이어를 통해 시작한다.
- 현재 해결은 플레이어 수명주기 정리에 집중하며, 삭제 직후 다음 영상 선택 정책 자체는 기존 ViewModel 흐름을 유지한다.

## SwiftUI와 AVPlayer 수명주기 포인트

- SwiftUI에서 뷰가 사라지는 것은 `AVPlayer`가 자동으로 정지·해제된다는 뜻이 아니다. 플레이어가 별도 객체로 살아 있으면 오디오 렌더링도 계속될 수 있다.
- `onDisappear`는 화면 표시 수명과 플레이어 수명을 연결하는 정리 지점이다.
- 시간 관찰자 제거(`stopProgressObservation`)는 진행률 콜백을 막는 작업이지, 미디어 재생을 멈추는 작업이 아니다.
- `pause()`는 재생을 멈추지만 현재 `AVPlayerItem`은 남길 수 있다. 삭제된 영상과의 연결까지 끊으려면 `replaceCurrentItem(with: nil)`이 필요하다.
- 활성 상태 변경(`isActive == false`)에서의 일시정지·seek와 뷰 제거 시의 플레이어 해제는 서로 다른 경로다. 둘 중 하나만 구현하면 삭제·화면 전환 경로에서 오디오가 남을 수 있다.

## 검증

확인해야 할 동작은 다음과 같다.

1. 릴캣 A 재생 중 삭제한다.
2. 다음 릴캣 B가 표시되는지 확인한다.
3. A의 오디오가 즉시 사라지고 B의 오디오만 재생되는지 확인한다.
4. 화면을 빠르게 전환하거나 비활성화한 뒤에도 A의 진행률 관찰 콜백이 남지 않는지 확인한다.

자동 검증은 macOS 환경에서 UIKit을 요구하는 iOS 타깃을 `swift test`로 직접 실행할 수 없어 제한되었다. 따라서 해당 명령의 실패는 이번 `AVPlayer` 정리 로직의 실패 측정이 아니라 테스트 환경 제약이다. 최종 확인에는 iOS Simulator 또는 실제 기기에서 삭제·전환 시나리오를 실행해야 한다.

## 남은 위험과 후속 확인

- `onDisappear`가 호출되는 모든 경로에서 플레이어를 비우는 것이 현재 화면 설계와 맞는지 확인한다.
- 삭제 직후 다음 영상의 `onChange(of: isActive)`가 새 플레이어에 정상적으로 `play()`를 호출하는지 Simulator에서 확인한다.
- 오디오 세션을 별도로 관리하는 코드가 있다면, 플레이어 아이템 제거만으로 세션이 남지 않는지도 함께 점검한다.

## 관련 코드

- `NyangJup/Packages/Package/Projects/Feature/RelayCat/Sources/View/RelayVideo.swift`
- `NyangJup/Packages/Package/Projects/Feature/RelayCat/Sources/ViewModel/RelayCatViewModel.swift`
