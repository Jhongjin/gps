# 번들 폰트

## Pretendard

- 버전 1.3.9 · SIL Open Font License 1.1 (`Pretendard-OFL.txt`)
- 출처: https://github.com/orioncactus/pretendard

`Regular(400)` 과 `Bold(700)` 두 자루만 담는다. 코드가 쓰는 굵기가 그 둘뿐이고
(디자인 스킬이 700 을 상한으로 둔다), OTF 한 자루가 1.6MB 라 굵기를 늘리는
비용이 작지 않다. 새 굵기가 정말 필요해지면 그때 추가한다.

### 왜 Geist 를 함께 담지 않았나

`DESIGN.md` 초안은 라틴에 Geist, 한글에 Pretendard 를 쓰는 조합이었다. 실제
화면을 보면 이 앱의 문장은 대부분 한 줄 안에서 한글과 숫자·라틴을 섞는다 —
`배터리 46%`, `정확도 85m`, `집까지 8분`. 서로 다른 두 패밀리를 섞으면 같은
줄에서 x-height 와 베이스라인이 어긋나 글줄이 울렁인다.

Pretendard 는 정확히 그 문제를 풀려고 만들어진 폰트다. 한글과 metric 이 맞춰진
라틴을 함께 담고 있어서, 한 패밀리만으로 두 문자를 일관되게 그린다. 용량도
절반이다. 그래서 라틴까지 Pretendard 로 통일했다.

`tnum`(고정폭 숫자)을 지원하므로 ETA·배터리·시각 표기에 `FontFeature.tabularFigures()`
를 그대로 쓸 수 있다.

### 다국어

일본어·힌디어·아랍어를 열려면 해당 문자용 폰트를 따로 담아야 한다. Pretendard
는 가나·한자·데바나가리·아랍 문자를 담지 않는다. 로케일을 여는 시점에
Noto 서브셋을 추가하고 `fontFamilyFallback` 에 연결한다.
