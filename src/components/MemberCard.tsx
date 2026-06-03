import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import type { Member } from '../data/mock';
import { locationModeLabels } from '../services/locationPolicy';
import { colors, radii, spacing } from '../theme/tokens';
import { StatusPill } from './StatusPill';

type Props = {
  member: Member;
};

export function MemberCard({ member }: Props) {
  return (
    <View style={styles.card}>
      <View style={[styles.avatar, member.status === 'moving' && styles.moving, member.status === 'alert' && styles.alert]}>
        <Text style={styles.avatarText}>{member.name.slice(0, 1)}</Text>
      </View>
      <View style={styles.body}>
        <View style={styles.row}>
          <Text numberOfLines={1} style={styles.name}>
            {member.name}
          </Text>
          <StatusPill status={member.status} />
        </View>
        <Text style={styles.meta}>
          {member.role} · {member.place} · {member.updatedAgo}
        </Text>
        <View style={styles.detailRow}>
          <MaterialCommunityIcons color={colors.subtle} name="battery-medium" size={15} />
          <Text style={styles.detail}>{member.battery}%</Text>
          <MaterialCommunityIcons color={colors.subtle} name="crosshairs-gps" size={15} />
          <Text style={styles.detail}>{locationModeLabels[member.precision]}</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flexDirection: 'row',
    gap: spacing.md,
    padding: spacing.md,
  },
  avatar: {
    alignItems: 'center',
    backgroundColor: colors.primary,
    borderRadius: radii.md,
    height: 44,
    justifyContent: 'center',
    width: 44,
  },
  moving: {
    backgroundColor: colors.blue,
  },
  alert: {
    backgroundColor: colors.danger,
  },
  avatarText: {
    color: colors.surface,
    fontSize: 18,
    fontWeight: '900',
  },
  body: {
    flex: 1,
    gap: 4,
    minWidth: 0,
  },
  row: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: spacing.sm,
    justifyContent: 'space-between',
  },
  name: {
    color: colors.ink,
    flex: 1,
    fontSize: 16,
    fontWeight: '900',
  },
  meta: {
    color: colors.muted,
    fontSize: 13,
  },
  detailRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 5,
  },
  detail: {
    color: colors.subtle,
    fontSize: 12,
    marginRight: spacing.xs,
  },
});
