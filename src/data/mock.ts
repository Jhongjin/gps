export type Coordinate = {
  latitude: number;
  longitude: number;
};

export type Member = {
  id: string;
  name: string;
  role: string;
  status: 'moving' | 'safe' | 'offline' | 'alert';
  battery: number;
  updatedAgo: string;
  place: string;
  precision: 'exact' | 'balanced' | 'area' | 'hidden';
  x: number;
  y: number;
  coordinate: Coordinate;
  route: Coordinate[];
  etaMinutes: number | null;
  speedLabel: string;
  headingDegrees: number;
};

export type Place = {
  id: string;
  name: string;
  rule: string;
  enabled: boolean;
  coordinate: Coordinate;
  radiusMeters: number;
};

export const myLocation: Coordinate = {
  latitude: 37.4976,
  longitude: 127.021,
};

export const members: Member[] = [
  {
    id: 'mira',
    name: '미라',
    role: '엄마',
    status: 'safe',
    battery: 82,
    updatedAgo: '방금',
    place: '집',
    precision: 'exact',
    x: 58,
    y: 34,
    coordinate: { latitude: 37.4981, longitude: 127.0276 },
    route: [
      { latitude: 37.4948, longitude: 127.0206 },
      { latitude: 37.4964, longitude: 127.0235 },
      { latitude: 37.4981, longitude: 127.0276 },
    ],
    etaMinutes: 0,
    speedLabel: '정지',
    headingDegrees: 88,
  },
  {
    id: 'jun',
    name: '준',
    role: '자녀',
    status: 'moving',
    battery: 46,
    updatedAgo: '2분 전',
    place: '학교 근처',
    precision: 'exact',
    x: 35,
    y: 58,
    coordinate: { latitude: 37.4947, longitude: 127.0145 },
    route: [
      { latitude: 37.4981, longitude: 127.0276 },
      { latitude: 37.4972, longitude: 127.0231 },
      { latitude: 37.4958, longitude: 127.0184 },
      { latitude: 37.4947, longitude: 127.0145 },
    ],
    etaMinutes: 8,
    speedLabel: '도보 4.1km/h',
    headingDegrees: 232,
  },
  {
    id: 'hana',
    name: '하나',
    role: '친구',
    status: 'safe',
    battery: 67,
    updatedAgo: '5분 전',
    place: '강남역',
    precision: 'balanced',
    x: 70,
    y: 64,
    coordinate: { latitude: 37.5015, longitude: 127.035 },
    route: [
      { latitude: 37.4976, longitude: 127.021 },
      { latitude: 37.4994, longitude: 127.028 },
      { latitude: 37.5015, longitude: 127.035 },
    ],
    etaMinutes: 12,
    speedLabel: '도보 3.6km/h',
    headingDegrees: 74,
  },
  {
    id: 'grandpa',
    name: '할아버지',
    role: '케어',
    status: 'alert',
    battery: 18,
    updatedAgo: '12분 전',
    place: '산책로',
    precision: 'area',
    x: 24,
    y: 28,
    coordinate: { latitude: 37.492, longitude: 127.0095 },
    route: [
      { latitude: 37.4936, longitude: 127.0132 },
      { latitude: 37.4928, longitude: 127.0114 },
      { latitude: 37.492, longitude: 127.0095 },
    ],
    etaMinutes: null,
    speedLabel: '신호 약함',
    headingDegrees: 216,
  },
];

export const places: Place[] = [
  {
    id: 'home',
    name: '집',
    rule: '도착과 출발 알림',
    enabled: true,
    coordinate: { latitude: 37.4981, longitude: 127.0276 },
    radiusMeters: 180,
  },
  {
    id: 'school',
    name: '학교',
    rule: '평일 08:00-17:00',
    enabled: true,
    coordinate: { latitude: 37.4947, longitude: 127.0145 },
    radiusMeters: 250,
  },
  {
    id: 'clinic',
    name: '병원',
    rule: '방문 후 보호자 확인',
    enabled: false,
    coordinate: { latitude: 37.492, longitude: 127.0095 },
    radiusMeters: 220,
  },
];

export const history = [
  { time: '08:10', title: '준 학교 도착', detail: '예상보다 4분 빨랐습니다.' },
  { time: '12:42', title: '미라 집 도착', detail: '정확도 18m' },
  { time: '17:18', title: '할아버지 산책 시작', detail: '케어 모드 활성' },
];
