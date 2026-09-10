# RelayCat 동영상 프리로드 학습 기록

## 문제와 목표

릴캣에서 스크롤로 다음 영상 셀이 나타날 때 즉시 재생되지 않고 버퍼링이 발생했다. 원인은 셀이 화면에 나타난 뒤에야 새 `AVPlayer`를 만들고 영상 로딩을 시작하는 구조였다. 목표는 현재 영상 주변의 플레이어를 미리 준비해, 셀 진입 시 준비된 플레이어를 재사용하는 것이다.

## 기존 방식과 변경 방식

기존에는 `RelayVideo`가 URL을 받아 내부에서 매번 `AVPlayer(url:)`를 생성했다.

```text
셀 등장 → RelayVideo 생성 → 새 AVPlayer 생성 → 메타데이터/버퍼 로딩 → 재생
```

변경 후에는 `RelayCatView`가 `RelayVideoPlayerPool`을 보유한다. 풀은 미디어 ID별 `AVPlayer`를 저장하고, `RelayCatCell`과 `RelayVideo`는 풀에서 전달받은 동일한 인스턴스를 사용한다.

```text
현재 항목 변경 → 풀에서 주변 동영상 AVPlayer 생성/준비
셀 등장 → 기존 AVPlayer를 전달받음 → 준비된 상태에서 재생
```

`AVPlayer` 인스턴스가 영상의 현재 로딩 상태와 버퍼를 가지고 있으므로, URL만 다시 받아 새 플레이어를 만들 때보다 이미 준비된 버퍼를 이어서 사용할 수 있다. 이것이 외부 플레이어 전달 방식이 프리로드로 동작하는 핵심이다.

## 프리로드 범위

현재 릴캣 배열의 인덱스를 기준으로 다음 네 항목을 대상으로 한다.

- 이전 1개: `currentIndex - 1`
- 현재 1개: `currentIndex`
- 다음 2개: `currentIndex + 1`, `currentIndex + 2`

배열 범위를 벗어난 인덱스는 제외하고, 이 범위 안에서도 미디어 타입이 동영상이며 URL이 유효한 항목만 플레이어를 만든다. 사진은 기존 이미지 로더 흐름을 사용한다.

프리로드는 현재 ID가 바뀌거나 서버에서 릴캣 목록이 갱신될 때 다시 실행된다. 따라서 스크롤 방향이 바뀌어도 새 현재 위치를 기준으로 범위가 이동한다.

## `preroll` 크래시와 해결

처음에는 플레이어 생성 직후 `player.preroll(atRate: 1)`을 호출했지만 다음 런타임 오류가 발생했다.

> AVPlayer cannot service a preroll request until its status is AVPlayerStatusReadyToPlay.

`AVPlayer(url:)` 직후에는 아직 준비 상태가 `.readyToPlay`가 아닐 수 있다. `preroll`은 준비되지 않은 플레이어를 대상으로 호출할 수 없으므로, 플레이어 상태가 `.readyToPlay`가 된 뒤에만 실행하도록 KVO(`observe(\.status, options: [.initial, .new])`)로 상태를 관찰한다. 관찰 객체는 풀에 미디어 ID별로 보관해 상태 관찰이 유지되도록 했다.

```swift
guard player.status == .readyToPlay else { return }
player.preroll(atRate: 1) { _ in }
```

이는 네트워크 실패나 준비 실패를 강제로 재생시키는 처리가 아니다. 해당 경우에는 `preroll`을 건너뛰며, 실제 기기에서 실패 상태 UX는 별도 검토가 필요하다.

## 메모리와 생명주기 정리

새 프리로드 범위가 계산되면 풀의 `players`와 `prerollObservers`를 주변 동영상 ID만 남기도록 필터링한다. 범위를 벗어난 ID에 대한 강한 참조와 상태 관찰이 사라져 플레이어가 계속 누적되지 않는다.

`RelayVideo.onDisappear`에서는 플레이어를 일시정지하지만 `replaceCurrentItem(with: nil)`은 호출하지 않는다. 후자는 현재 아이템과 버퍼를 제거해 프리로드 효과를 없애기 때문이다. 비활성화 시에는 `pause()` 후 시작 위치로 `seek`해 다음 노출 때 처음부터 재생한다. 실제 메모리 압박 상황에서의 AVPlayer 캐시 동작은 기기·OS·스트림 형식에 따라 달라질 수 있다.

## 변경 파일의 역할

- `RelayVideo.swift`: `RelayVideoPlayerPool` 추가, 범위 계산·플레이어 보관·ready 이후 preroll·범위 밖 정리. `RelayVideo`가 외부 `AVPlayer`를 받도록 변경.
- `RelayCatView.swift`: 풀을 상태로 보유하고 셀에 미디어 ID별 플레이어를 전달. 현재 항목과 목록 변경 시 프리로드 갱신.
- `RelayCatCell.swift`: URL로 `RelayVideo`를 만들던 코드를 풀에서 받은 플레이어 전달 방식으로 변경.

## 검증과 남은 확인 사항

대화 기록 기준 iOS Simulator 대상 `FeatureRelayCat` 빌드는 성공했다. UIKit 의존성 때문에 SwiftPM 단독 테스트는 macOS 환경에서 실행할 수 없었다. 아직 실제 기기에서 셀룰러/Wi‑Fi별 전환 지연, 다음 두 영상의 동시 버퍼링, 메모리 사용량을 계측한 결과는 없다. 따라서 프리로드 범위가 체감 재생 지연을 줄이는지는 실제 스크롤 시나리오와 Instruments 네트워크·메모리 측정으로 후속 확인해야 한다.
