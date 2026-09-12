# Issue #14 学習ログ：診療科マスタ

- 対象：[Issue #14](https://github.com/aya-tkd/portfolio-app/issues/14)、[PR #31](https://github.com/aya-tkd/portfolio-app/pull/31)、[セッション #19](https://github.com/aya-tkd/portfolio-app/issues/19)
- 記録区分：Issue #15のPRフィードバックでの遡及評価。根拠は保持された開発チャット。以下は技術的な要約で、GitHub上の発言を引用したものではない。
- 自己評価：責務の違いは「3割ぐらい捉えた」との申告があり、後の振り返りでは診療科対応で理解が深まったとの認識が示された。

| 観点 | 会話に表れた根拠 | 前→後 | 確かさ・未確認事項 |
|---|---|---|---|
| Vue・APIの役割 | Vueが画面処理を引き取り、api.js経由でサーバーへ送ると整理した | 旧beginner→L2 | 確認あり。通信後の状態更新を説明するところは未確認 |
| HTTPメソッド | PATCHを新規と捉え、GET/DELETEとの差を質問した。説明で訂正した | 旧beginner→L1 | 訂正後の定着は未確認。他の観点の進歩を打ち消さない |
| ルーティング | ViteはURLの受け渡し、routes.rbはController選択と捉えてコードとの対応を問うた | 旧beginner→L2 | 暫定。resourcesの順序とHTTP対応には説明を要した |
| Active Record | Modelにfind/newが見えない理由、保存箇所、ORMとの関係を質問した | 旧beginner→L1 | 継承・ORMの説明後に自身で処理を追えたかは未確認 |
| Model・Service・DTO | 複雑な業務フローのService分離を言い換え、予約と患者・診療科が関わる場合のModel、表示DTOとの差を掘り下げた | 旧beginner→L2 | 暫定。「Modelは1テーブルの単純処理のみ」という理解は修正途中 |
| CSSフレームワーク | BootstrapとTailwindの用途や違いを質問し、説明を受けた | 旧beginner→L1 | 選択理由を自身で説明する場面は未確認 |

旧beginnerには細分化がなかったため、これは数値の昇格履歴ではなく、新しい尺度への初回割り当てである。質問の具体性と言い換えは評価材料として十分であり、全項目を一括で据え置いた以前の判断を訂正する。

次はユーザーマスタ等で、フォームの値がJSONとなり、ルート・Controller・Modelを通って戻る一往復を実ファイルで説明する。通常のレビュー会話でユーザーがどこを追えるかを観測し、出題や手入力実装を要求しない。
