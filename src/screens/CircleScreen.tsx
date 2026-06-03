import React from 'react';
import { Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { places } from '../data/mock';
import { colors, radii, spacing } from '../theme/tokens';

export function CircleScreen() {
  return (
    <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      <Text style={styles.title}>가족 서클</Text>
      <View style={styles.inviteCard}>
        <MaterialCommunityIcons color={colors.primary} name="link-variant-plus" size={28} />
        <View style={styles.inviteText}>
          <Text style={styles.cardTitle}>초대 링크 만들기</Text>
          <Text style={styles.cardBody}>초대받은 사람은 공유 범위와 광고 안내를 보고 직접 동의합니다.</Text>
        </View>
      </View>
      <View style={styles.actions}>
        <Pressable accessibilityRole="button" style={styles.actionButton}>
          <MaterialCommunityIcons color={colors.primary} name="account-plus-outline" size={20} />
          <Text style={styles.actionText}>멤버 초대</Text>
        </Pressable>
        <Pressable accessibilityRole="button" style={styles.actionButton}>
          <MaterialCommunityIcons color={colors.primary} name="map-marker-plus-outline" size={20} />
          <Text style={styles.actionText}>장소 추가</Text>
        </Pressable>
      </View>
      <Text style={styles.sectionTitle}>장소 알림</Text>
      {places.map((place) => (
        <View key={place.id} style={styles.placeRow}>
          <View style={styles.placeCopy}>
            <Text style={styles.placeName}>{place.name}</Text>
            <Text style={styles.placeRule}>{place.rule}</Text>
          </View>
          <Switch
            accessibilityLabel={`${place.name} 알림`}
            ios_backgroundColor={colors.border}
            thumbColor={place.enabled ? colors.primary : colors.surface}
            trackColor={{ false: colors.border, true: colors.primarySoft }}
            value={place.enabled}
          />
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: {
    gap: spacing.md,
    paddingBottom: spacing.xl,
  },
  title: {
    color: colors.ink,
    fontSize: 28,
    fontWeight: '900',
  },
  inviteCard: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flexDirection: 'row',
    gap: spacing.md,
    padding: spacing.md,
  },
  inviteText: {
    flex: 1,
  },
  cardTitle: {
    color: colors.ink,
    fontSize: 16,
    fontWeight: '900',
  },
  cardBody: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
    marginTop: 3,
  },
  actions: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  actionButton: {
    alignItems: 'center',
    backgroundColor: colors.primarySoft,
    borderRadius: radii.md,
    flex: 1,
    flexDirection: 'row',
    gap: 6,
    justifyContent: 'center',
    minHeight: 48,
  },
  actionText: {
    color: colors.primary,
    fontSize: 14,
    fontWeight: '900',
  },
  sectionTitle: {
    color: colors.ink,
    fontSize: 18,
    fontWeight: '900',
  },
  placeRow: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: spacing.md,
  },
  placeCopy: {
    flex: 1,
    paddingRight: spacing.md,
  },
  placeName: {
    color: colors.ink,
    fontSize: 15,
    fontWeight: '900',
  },
  placeRule: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 2,
  },
});
