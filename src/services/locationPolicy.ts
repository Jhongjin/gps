export type LocationMode = 'precise' | 'balanced' | 'area' | 'hidden';

export const locationModeLabels: Record<LocationMode, string> = {
  precise: '정확 위치',
  balanced: '균형',
  area: '동네만',
  hidden: '숨김',
};

export function syncIntervalSeconds(mode: LocationMode, isMoving: boolean, battery: number) {
  if (mode === 'hidden') return null;
  if (battery <= 15) return isMoving ? 300 : 900;
  if (mode === 'precise') return isMoving ? 20 : 180;
  if (mode === 'balanced') return isMoving ? 60 : 300;
  return isMoving ? 300 : 900;
}

export function disclosureForMode(mode: LocationMode) {
  if (mode === 'precise') {
    return '서클 멤버가 지도에서 정확한 위치와 마지막 업데이트 시간을 볼 수 있습니다.';
  }
  if (mode === 'balanced') {
    return '서클 멤버에게 현재 장소와 대략적인 위치를 공유합니다.';
  }
  if (mode === 'area') {
    return '서클 멤버에게 동네 수준의 위치만 공유합니다.';
  }
  return '위치 공유를 멈추고 마지막 위치를 새로 업데이트하지 않습니다.';
}
