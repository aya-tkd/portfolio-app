# User Technical Profile

この文書は、説明の深さを調整するための技術理解度だけを記録します。個人情報、転職活動上の事情、家族情報、秘密情報は記録しません。

## 初期プロファイル

| 分野 | 目安 |
|---|---|
| C# / .NET | experienced |
| SQL / RDB | experienced |
| 業務システム開発 | experienced |
| Git | intermediate |
| HTTP | beginner |
| Ruby | beginner |
| Ruby on Rails | beginner |
| Vue | beginner |
| JavaScript | beginner |
| Web architecture | beginner |

## 現在の観点別プロファイル

上の表は開始時の自己申告・説明方針の履歴。現在の説明には以下を用いる。段階は[評価規約](progress-rules.md)のL0〜L5で、Web全体を一律beginnerとは扱わない。

| 観点 | 現在 | 確かさ・根拠 | 次に見ること |
|---|---|---|---|
| Vueと画面処理・APIの分担 | L2 | 確認あり：画面処理をVue、通信をapi.jsへ分けると自分の言葉で整理（#14） | フォーム値→送信データ→通知を実コードで説明する |
| HTTPメソッド | L1 | POST/PATCH/GET/DELETEの説明を受けた。PATCHを新規と捉えた誤解の訂正後は未確認（#14） | 次の機能でURL・メソッド・操作の対応を読む |
| Vite→Railsルート→Controller | L2 | 暫定：Viteの受け渡しとroutes.rbのController選択を捉えて具体的な対応を質問（#14） | 一つのAPIについてメソッド・URL・actionをつなぐ |
| Active Recordの永続化 | L1 | 継承とsave/find/newの説明を受けた。自身の説明による定着は未確認（#14） | Controllerからsaveまでの呼び出しを読む |
| Model・Service・DTOの責務 | L2 | 暫定：複数テーブル処理の分担を言い換え、結合した予約データのモデル化を質問（#14） | 「1テーブルならModel」という限定を外し、ルールと表示用途を区別する |
| Ruby構文・JavaScript言語機能 | L1 | 触れた経験・説明あり。単独の言語理解は未観測 | 実際の修正で使う構文だけ説明する |
| Bootstrap・Tailwindの選択 | L1 | 違いの説明を受けた。自分で選択理由を説明する場面は未観測（#14） | UI要件に対して選ぶ理由を会話で扱う |

更新根拠：[Issue #14の遡及評価](issues/issue-14.md)、[Issue #15の学習ログ](issues/issue-15.md)。既存のC#/.NET・SQL・業務知識は引き続き説明の足場にする。上の段階はWebの対象概念だけの評価である。

## 更新方針

理解度は作業回数だけで更新しません。概念を自分の言葉で説明できた、類似の設計判断を自力で行えた、レビューで問題を指摘できた、より高度な質問ができた、といった根拠を残します。

説明は実際の開発で必要になったタイミングに行い、既存のC#/.NETやRDBの知識との対応関係を活用します。ただし、RubyやWebの仕組みをC#/.NETと同一視しないよう差異も説明します。

PR準備と各PRフィードバック対応完了前に、[評価規約](progress-rules.md)に従ってIssue別ログとこの表を見直します。評価目的の出題は行いません。
