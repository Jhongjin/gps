import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors, radii, spacing } from '../theme/tokens';
import type { Member } from '../data/mock';

const statusCopy: Record<Member['status'], { label: string; color: string; bg: string }> = {
  moving: { label: '이동 중', color: colors.blue, bg: colors.blueSoft },
  safe: { label: '안전', color: colors.primary, bg: colors.primarySoft },
  offline: { label: '오프라인', color: colors.muted, bg: colors.surfaceAlt },
  alert: { label: '확인 필요', color: colors.danger, bg: colors.dangerSoft },
};

type Props = {
  status: Member['status'];
};

export function StatusPill({ status }: Props) {
  const item = statusCopy[status];
  return (
    <View style={[styles.pill, { backgroundColor: item.bg }]}>
      <Text style={[styles.text, { color: item.color }]}>{item.label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: 'flex-start',
    borderRadius: radii.sm,
    paddingHorizontal: spacing.xs,
    paddingVertical: spacing.xxs,
  },
  text: {
    fontSize: 12,
    fontWeight: '900',
  },
});
