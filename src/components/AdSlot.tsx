import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors, radii, spacing } from '../theme/tokens';

type Props = {
  surface: 'history' | 'settings';
};

export function AdSlot({ surface }: Props) {
  const label = surface === 'history' ? '동네 안전 소식' : '무료 운영 지원 광고';
  const body =
    surface === 'history'
      ? '정확 위치를 광고 타깃팅에 사용하지 않는 운영 지원 광고입니다.'
      : '민감 카테고리와 정확 위치 기반 타깃팅을 제외한 광고만 허용합니다.';

  return (
    <View accessibilityLabel="광고 영역" style={styles.slot}>
      <Text style={styles.badge}>AD</Text>
      <View style={styles.copy}>
        <Text style={styles.title}>{label}</Text>
        <Text style={styles.body}>{body}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  slot: {
    alignItems: 'flex-start',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flexDirection: 'row',
    gap: spacing.sm,
    padding: spacing.md,
  },
  badge: {
    backgroundColor: colors.accentSoft,
    borderRadius: radii.sm,
    color: colors.accent,
    fontSize: 11,
    fontWeight: '900',
    overflow: 'hidden',
    paddingHorizontal: spacing.xs,
    paddingVertical: spacing.xxs,
  },
  copy: {
    flex: 1,
  },
  title: {
    color: colors.ink,
    fontSize: 14,
    fontWeight: '900',
  },
  body: {
    color: colors.muted,
    fontSize: 12,
    lineHeight: 17,
    marginTop: 3,
  },
});
