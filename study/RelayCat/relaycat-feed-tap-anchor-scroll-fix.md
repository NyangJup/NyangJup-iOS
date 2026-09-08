# RelayCat 피드 셀 탭 시 선택 항목이 바뀌어 보인 문제

## 문제와 관찰

피드에서 중간 셀을 탭하면 `FeedViewModel`은 선택한 미디어 ID를 `RelayCat` 라우트로 전달한다. 그런데 RelayCat 상세 화면이 열린 직후 선택한 셀이 아니라 다른 항목이 보일 수 있었다.

핵심 제약은 두 가지였다.

- 네트워크 응답을 기다리는 동안에도 탭한 콘텐츠를 먼저 보여 줘야 한다.
- 응답 후에는 탭한 항목의 앞뒤 콘텐츠를 포함한 새 목록으로 교체해야 한다.

## 실제 원인

초기 진입과 데이터 교체의 순서는 다음과 같다.

```text
피드 셀 탭
  ↓
RelayCatViewModel.items = [탭한 anchor 1개]
  ↓ 화면은 우선 anchor를 렌더링
초기 Relay API 응답 수신
  ↓
items = [앞 항목들, anchor, 뒤 항목들] 로 교체
  ↓
기존 ScrollView의 위치 오프셋은 새 배열 기준으로 자동 보정되지 않음
  ↓
배열의 첫 항목이 보이며 “다른 콘텐츠가 열렸다”고 보임
```

`currentItemId`는 처음부터 탭한 미디어 ID였고, 서버 응답 뒤에도 같은 ID가 다시 설정될 수 있었다. 따라서 `.scrollPosition(id:)`에 같은 값을 재대입하는 것만으로는 목록 교체 뒤 실제 스크롤 이동이 보장되지 않았다. 서버 응답 자체는 `anchorIndex`로 anchor의 위치를 제공하며, 문제는 라우팅이나 API의 ID가 아니라 목록 교체 후 화면 위치였다.

## 고려한 해결책

| 방법 | 구현 방식 | 장점 | 단점 및 트레이드오프 |
|---|---|---|---|
| `ScrollViewReader.scrollTo` | 초기 목록 응답 완료 후 `anchorId`를 명시적으로 `scrollTo` | 실제 위치 이동 의도가 분명하고, 새 배열에서 ID를 정확히 찾음 | `ScrollViewReader`, 로딩 상태, 1회 실행 플래그가 필요함. 레이아웃 반영을 위해 다음 메인 런루프로 넘김 |
| `.scrollPosition` 재설정 | 응답 후 `nil`을 넣었다가 다시 anchor ID를 대입 | 변경 범위가 작고 기존 바인딩을 재사용함 | `nil` 순간 현재 항목/메뉴 상태가 흔들릴 수 있고, 비동기 이벤트가 값을 덮어쓸 수 있음. 간접적인 스크롤 제어임 |

선택한 셀을 반드시 기준점으로 맞춰야 하고, 이후 페이지네이션에서 사용자의 위치를 보존해야 하므로 `ScrollViewReader + scrollTo` 방식을 선택했다.

## 적용한 구현

### 1. 최초 로드 완료 상태를 ViewModel에 기록

`RelayCatViewModel.State`에 `hasLoadedInitialRelay`를 추가한다. 초기화 시에는 `false`이고, 초기 Relay 응답으로 `items`와 `currentItemId`를 갱신한 뒤 `true`로 바꾼다.

```swift
var hasLoadedInitialRelay = false
```

```swift
state.items = response.items
state.previousCursor = response.previousCursor
state.nextCursor = response.nextCursor

if response.items.indices.contains(response.anchorIndex) {
    state.currentItemId = response.items[response.anchorIndex].mediaId
}
state.hasLoadedInitialRelay = true
```

상태를 목록 교체 뒤에 바꾸는 이유는, `true` 변경을 “스크롤할 수 있는 초기 목록이 준비됐다”는 신호로 사용하기 위해서다.

### 2. `ScrollViewReader`로 목록을 감싸고 anchor로 한 번 이동

각 Relay 셀은 이미 미디어 ID를 `.id(item.mediaId)`로 갖고 있으므로, `ScrollViewReader`가 제공하는 proxy로 해당 ID를 직접 찾을 수 있다.

```swift
@State private var didPositionInitialItem = false

ScrollViewReader { scrollProxy in
    // ScrollView + LazyVStack + scrollPosition
    .onChange(of: viewModel.state.hasLoadedInitialRelay) { _, hasLoaded in
        guard hasLoaded, !didPositionInitialItem else { return }

        didPositionInitialItem = true
        DispatchQueue.main.async {
            scrollProxy.scrollTo(viewModel.state.anchorId, anchor: .top)
        }
    }
}
```

`didPositionInitialItem`은 초기 응답에서만 이동하도록 제한한다. 이후 이전/다음 페이지가 추가될 때 같은 anchor로 되돌아가면 사용자의 탐색 위치가 깨지므로, 페이지네이션에는 이 보정이 재실행되지 않아야 한다. `DispatchQueue.main.async`는 응답으로 바뀐 목록과 셀 레이아웃이 반영된 다음 proxy가 ID를 찾도록 한 타이밍 보정이다.

## 검증과 학습 포인트

테스트에서는 다음 상태 전이를 확인한다.

1. ViewModel 생성 직후 `items`는 탭한 Relay 하나이고 `hasLoadedInitialRelay == false`다.
2. 초기 fetch가 끝나면 응답 목록으로 교체되고, `currentItemId`는 탭한 미디어 ID를 유지한다.
3. 응답 처리 후 `hasLoadedInitialRelay == true`가 된다.
4. 앞·뒤 cursor도 응답값으로 저장된다.

검증 결과:

- `FeatureRelayCat` iOS 대상 빌드 성공.
- RelayCat ViewModel 테스트에 최초 로드 상태의 `false → true` 검증을 추가.
- `swift test`는 macOS 대상 실행에서 UIKit 모듈을 지원하지 않아 검증할 수 없음.

## 남은 위험과 후속 확인

- 실제 기기에서 느린 네트워크, 광고 삽입, 셀 lazy 생성이 겹칠 때 `scrollTo`가 anchor 위치를 정확히 맞추는지 확인할 필요가 있다.
- `anchorId`에 해당하는 셀이 응답에 없거나 `anchorIndex`가 범위를 벗어나면 현재 구현은 명시적 이동을 수행하지 않는다. 이 경우의 사용자 표시 정책은 별도 결정 사항이다.
- macOS `swift test` 대신 iOS 시뮬레이터/기기에서 FeatureRelayCat 테스트를 실행하는 검증 경로가 필요하다.

## 관련 파일

- `NyangJup/Packages/Package/Projects/Feature/RelayCat/Sources/View/RelayCatView.swift`
- `NyangJup/Packages/Package/Projects/Feature/RelayCat/Sources/ViewModel/RelayCatViewModel.swift`
- `NyangJup/Packages/Package/Projects/Feature/RelayCat/Tests/FeatureRelayCatTests.swift`

