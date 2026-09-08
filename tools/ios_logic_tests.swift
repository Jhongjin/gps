// AppDelegate.swift 의 GyeotePortable 구역을 검증한다.
// `tools/check_ios_logic.py` 가 그 구역을 잘라내 이 파일과 함께 컴파일하고 실행한다.
// Xcode 없이 Windows 의 Swift 툴체인으로 돈다 — 그래서 Foundation 만 쓴다.

import Foundation

var failures = 0

func check(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
  if !condition {
    failures += 1
    print("FAIL \(message)  (\(line))")
  }
}

let lat = 37.5
let lng = 127.0
func north(_ meters: Double) -> Double { lat + meters / 111320.0 }
func m(_ h: Int, _ min: Int = 0) -> Int { h * 60 + min }

// --- 민감 장소 ---
let home = GyeotePrivatePlaces.Place(lat: lat, lng: lng, radiusM: 300)

do {
  let a = GyeotePrivatePlaces.mask([home], lat: north(10), lng: lng)
  let b = GyeotePrivatePlaces.mask([home], lat: north(250), lng: lng)
  check(a == b, "반경 안의 서로 다른 지점이 같은 값이 된다")
  check(abs(a.lat - lat) < 1e-9, "스냅 결과는 중심이다")
}
do {
  let outside = north(900)
  let masked = GyeotePrivatePlaces.mask([home], lat: outside, lng: lng)
  check(abs(masked.lat - outside) < 1e-9, "반경 밖이면 좌표를 건드리지 않는다")
}
do {
  let once = GyeotePrivatePlaces.mask([home], lat: north(120), lng: lng)
  let twice = GyeotePrivatePlaces.mask([home], lat: once.lat, lng: once.lng)
  check(once == twice, "두 번 걸어도 결과가 같다")
}
do {
  let wide = GyeotePrivatePlaces.Place(lat: north(500), lng: lng, radiusM: 1000)
  let covering = GyeotePrivatePlaces.covering([wide, home], lat: north(100), lng: lng)
  check(covering == home, "겹치면 중심이 가까운 쪽을 고른다")
}
do {
  check(GyeotePrivatePlaces.fromPolicy(["mode": "precise"]).isEmpty, "장소 없는 정책은 빈 목록")
  check(GyeotePrivatePlaces.fromPolicy(["privatePlaces": ["not a map", 7]]).isEmpty, "망가진 정책에서 죽지 않는다")
  let places = GyeotePrivatePlaces.fromPolicy([
    "privatePlaces": [
      ["lat": lat, "lng": lng, "radiusM": 300],
      ["lat": lat, "lng": lng],
      ["lat": lat, "lng": lng, "radiusM": 0],
      ["lat": lat, "lng": lng, "radiusM": 150, "name": "정신과"],
    ],
  ])
  check(places.count == 2, "항목이 망가져 있으면 그 항목만 버린다 (\(places.count))")
}

// --- 조용한 시간 ---
do {
  let night = GyeoteQuietHours.windowOf("22:00", "07:00")!
  check(night.contains(m(23)), "자정 넘는 창: 23시")
  check(night.contains(m(3)), "자정 넘는 창: 3시")
  check(night.contains(m(22)), "자정 넘는 창: 시작 경계 포함")
  check(!night.contains(m(7)), "자정 넘는 창: 끝 경계 제외")
  check(!night.contains(m(12)), "자정 넘는 창: 낮은 밖")
}
do {
  let work = GyeoteQuietHours.windowOf("09:00", "17:00")!
  check(work.contains(m(9)) && work.contains(m(12, 30)), "낮 창 안")
  check(!work.contains(m(17)) && !work.contains(m(8, 59)) && !work.contains(m(23)), "낮 창 밖")
}
do {
  check(GyeoteQuietHours.windowOf("25:00", "07:00") == nil, "25시는 창이 아니다")
  check(GyeoteQuietHours.windowOf("22", "07:00") == nil, "분 없는 시각은 창이 아니다")
  check(GyeoteQuietHours.windowOf(nil, "07:00") == nil, "한쪽 없으면 창이 아니다")
  check(GyeoteQuietHours.windowOf("22:00", "22:00") == nil, "같은 시각은 창이 아니다")
  check(GyeoteQuietHours.windowOf("ab:cd", "07:00") == nil, "글자는 창이 아니다")
}
do {
  let windows = GyeoteQuietHours.windows(from: [
    ["id": "home", "quietStart": "22:00", "quietEnd": "07:00"],
    ["id": "school"],
    ["id": "broken", "quietStart": "99:00", "quietEnd": "07:00"],
  ])
  check(windows == ["home": "22:00|07:00"], "등록 페이로드에서 창만 남는다 (\(windows))")
  check(GyeoteQuietHours.isQuiet(windows: windows, ids: ["home"], minuteOfDay: m(2)), "집은 새벽에 조용")
  check(!GyeoteQuietHours.isQuiet(windows: windows, ids: ["home"], minuteOfDay: m(12)), "집은 낮에 안 조용")
  check(!GyeoteQuietHours.isQuiet(windows: windows, ids: ["school"], minuteOfDay: m(2)), "창 없는 곳은 안 조용")
  check(GyeoteQuietHours.isQuiet(windows: windows, ids: ["school", "home"], minuteOfDay: m(2)), "겹치면 하나라도 조용하면 조용")
}

// --- 문구 ---
do {
  check(GyeoteNativeStrings.text("place_alert_arrived", languages: ["ko-KR"]) == "저장한 장소 반경에 도착했습니다.", "ko 문구")
  check(GyeoteNativeStrings.text("place_alert_arrived", languages: ["en-US"]) == "Arrived at a saved place.", "en 문구")
  check(GyeoteNativeStrings.text("place_alert_arrived", languages: ["de-DE"]) == "Arrived at a saved place.", "모르는 언어는 영어")
  check(GyeoteNativeStrings.text("nope", languages: ["ko"]) == "nope", "모르는 키는 키 그대로")
}

if failures == 0 {
  print("iOS portable logic: all checks passed")
  exit(0)
} else {
  print("iOS portable logic: \(failures) failing")
  exit(1)
}
