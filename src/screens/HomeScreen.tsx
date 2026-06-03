import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { MapPreview } from '../components/MapPreview';
import { MemberCard } from '../components/MemberCard';
import { members } from '../data/mock';
import { colors, radii, spacing } from '../theme/tokens';

export function HomeScreen() {
  return (
    <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      <View style={styles.heroRow}>
        <View>
          <Text style={styles.kicker}>우리 서클</Text>
          <Text style={styles.title}>4명 공유 중</Text>
        </View>
        <Pressable accessibilityRole="button" style={styles.sosButton}>
          <MaterialCommunityIcons color={colors.surface} name="alarm-light-outline" size={20} />
          <Text style={styles.sosText}>SOS</Text>
        </Pressable>
      </View>

      <View style={styles.mapHeader}>
        <View>
          <Text style={styles.mapTitle}>서울 서초구 근처</Text>
          <Text style={styles.mapMeta}>정확 2명 · 균형 1명 · 동네만 1명</Text>
        </View>
        <View style={styles.mapActions}>
          <MaterialCommunityIcons color={colors.primary} name="crosshairs-gps" size={20} />
          <MaterialCommunityIcons color={colors.primary} name="map-marker-plus-outline" size={20} />
        </View>
      </View>
      <MapPreview members={members} />

      <View style={styles.banner}>
        <MaterialCommunityIcons color={colors.primary} name="shield-account-outline" size={22} />
        <Text style={styles.bannerText}>정확 위치는 허용한 서클에만 공유됩니다. 광고에는 정확 위치, SOS, 권한 데이터를 사용하지 않습니다.</Text>
      </View>

      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>멤버</Text>
        <Text style={styles.sectionAction}>초대 코드 4821</Text>
      </View>
      {members.map((member) => (
        <MemberCard key={member.id} member={member} />
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: {
    gap: spacing.md,
    paddingBottom: spacing.xl,
  },
  heroRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  kicker: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900',
  },
  title: {
    color: colors.ink,
    fontSize: 28,
    fontWeight: '900',
    letterSpacing: 0,
  },
  sosButton: {
    alignItems: 'center',
    backgroundColor: colors.danger,
    borderRadius: radii.md,
    flexDirection: 'row',
    gap: 5,
    minHeight: 44,
    paddingHorizontal: spacing.md,
  },
  sosText: {
    color: colors.surface,
    fontSize: 14,
    fontWeight: '900',
  },
  mapHeader: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: spacing.sm,
  },
  mapTitle: {
    color: colors.ink,
    fontSize: 14,
    fontWeight: '900',
  },
  mapMeta: {
    color: colors.muted,
    fontSize: 12,
    marginTop: 2,
  },
  mapActions: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  banner: {
    alignItems: 'center',
    backgroundColor: colors.primarySoft,
    borderColor: 'rgba(15, 106, 83, 0.12)',
    borderRadius: radii.md,
    borderWidth: 1,
    flexDirection: 'row',
    gap: spacing.sm,
    padding: spacing.md,
  },
  bannerText: {
    color: colors.primaryStrong,
    flex: 1,
    fontSize: 13,
    fontWeight: '800',
    lineHeight: 19,
  },
  sectionHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  sectionTitle: {
    color: colors.ink,
    fontSize: 18,
    fontWeight: '900',
  },
  sectionAction: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900',
  },
});
