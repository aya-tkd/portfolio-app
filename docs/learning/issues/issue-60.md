# Issue #60 学習記録

通常記録。親Issue [#60](https://github.com/aya-tkd/portfolio-app/issues/60)、設計 [#95](https://github.com/aya-tkd/portfolio-app/issues/95)、テスト [#96](https://github.com/aya-tkd/portfolio-app/issues/96)、セッションログ [#97](https://github.com/aya-tkd/portfolio-app/issues/97)。

| 観点 | 会話に表れた根拠 | 前→後 | 確かさ | 次の機会 |
|---|---|---|---|---|
| API契約・FE/BEの責務 | API契約表の「操作」「呼出元→受け先」はFE側の画面設計であり、API契約から分けて考える理解でよいか質問。一般的にはAPI仕様はAPI単位の正本を持ち、画面Docは利用者側の操作と利用概要を記載する分担が妥当と整理し、Issue要件も一般的なWeb設計として分かりやすい形へ再構成するよう判断した（チャット）。 | L2→L2 | 確認あり（設計の責務境界を具体的に比較。ただし実コードのAPIを入力から応答まで説明した根拠ではない） | 画面DocのAPI連携要約とControllerの許可入力・応答を、一つのAPIで対応付けて読む |

API仕様の正本と画面Docの利用者向け要約を区別し、OpenAPI等の独立仕様を今の規模で導入しない案を採用。呼出元／受け先は必須のAPI契約項目とせず、画面のAPI利用挙動が変われば対応Docを同じIssue/PRで更新・実装照合するルールを設計した。設計判断の根拠として扱い、実装理解やHTTP経路の説明力が実証されたとは見なさない。
