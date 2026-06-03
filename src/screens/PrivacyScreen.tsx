import React, { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { AdSlot } from '../components/AdSlot';
import { disclosureForMode, LocationMode, locationModeLabels } from '../services/locationPolicy';
import { colors, radii, spacing } from '../theme/tokens';

const modes: LocationMode[] = ['precise', 'balanced', 'area', 'hidden'];

export function PrivacyScreen() {
  const [mode, setMode] = useState<LocationMode>('balanced');

  return (
    <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      <Text style={styles.title}>프라이버시</Text>
      <View style={styles.card}>
        <View style={styles.cardHeader}>
          <MaterialCommunityIcons color={colors.primary} name="eye-check-outline" size={24} />
          <Text style={styles.cardTitle}>내 위치를 볼 수 있는 사람</Text>
        </View>
        <Text style={styles.body}>가족 서클 3명, 여행 서클 1명이 현재 위치를 볼 수 있습니다.</Text>
        <View style={styles.viewerList}>
          <View style={styles.viewerRow}>
            <Text style={styles.viewerName}>민정</Text>
            <Text style={styles.viewerMeta}>방금 조회</Text>
          </View>
          <View style={styles.viewerRow}>
            <Text style={styles.viewerName}>준호</Text>
            <Text style={styles.viewerMeta}>어제 21:10</Text>
          </View>
        </View>
      </View>
      <Text style={styles.sectionTitle}>공유 정확도</Text>
      <View style={styles.modeGrid}>
        {modes.map((item) => {
          const active = item === mode;
          return (
            <Pressable
              accessibilityRole="button"
              key={item}
              onPress={() => setMode(item)}
              style={[styles.modeButton, active && styles.modeActive]}
            >
              <Text style={[styles.modeText, active && styles.modeTextActive]}>{locationModeLabels[item]}</Text>
            </Pressable>
          );
        })}
      </View>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>{locationModeLabels[mode]}</Text>
        <Text style={styles.body}>{disclosureForMode(mode)}</Text>
      </View>
      <View style={styles.card}>
        <View style={styles.cardHeader}>
          <MaterialCommunityIcons color={colors.accent} name="advertisements" size={24} />
          <Text style={styles.cardTitle}>광고와 데이터</Text>
        </View>
        <Text style={styles.body}>안전 기능은 모두 무료입니다. 광고는 정확 위치, SOS, 권한 화면에서 사용하지 않습니다.</Text>
      </View>
      <AdSlot surface="settings" />
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
  card: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    gap: spacing.sm,
    padding: spacing.md,
  },
  cardHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: spacing.sm,
  },
  cardTitle: {
    color: colors.ink,
    fontSize: 16,
    fontWeight: '900',
  },
  body: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
  },
  viewerList: {
    gap: spacing.xs,
  },
  viewerRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  viewerName: {
    color: colors.muted,
    fontSize: 13,
  },
  viewerMeta: {
    color: colors.ink,
    fontSize: 13,
    fontWeight: '900',
  },
  sectionTitle: {
    color: colors.ink,
    fontSize: 18,
    fontWeight: '900',
  },
  modeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  modeButton: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    justifyContent: 'center',
    minHeight: 46,
    minWidth: '47%',
    paddingHorizontal: spacing.sm,
  },
  modeActive: {
    backgroundColor: colors.primarySoft,
    borderColor: colors.primary,
  },
  modeText: {
    color: colors.muted,
    fontSize: 14,
    fontWeight: '900',
  },
  modeTextActive: {
    color: colors.primary,
  },
});
