import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { AdSlot } from '../components/AdSlot';
import { history } from '../data/mock';
import { colors, radii, spacing } from '../theme/tokens';

export function HistoryScreen() {
  return (
    <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      <Text style={styles.title}>오늘 기록</Text>
      <View style={styles.summary}>
        <View style={styles.summaryItem}>
          <Text style={styles.summaryNumber}>3</Text>
          <Text style={styles.summaryLabel}>장소 알림</Text>
        </View>
        <View style={styles.summaryItem}>
          <Text style={styles.summaryNumber}>0</Text>
          <Text style={styles.summaryLabel}>긴급 알림</Text>
        </View>
        <View style={styles.summaryItem}>
          <Text style={styles.summaryNumber}>12분</Text>
          <Text style={styles.summaryLabel}>최대 지연</Text>
        </View>
      </View>
      {history.map((item) => (
        <View key={`${item.time}-${item.title}`} style={styles.event}>
          <Text style={styles.time}>{item.time}</Text>
          <View style={styles.eventBody}>
            <Text style={styles.eventTitle}>{item.title}</Text>
            <Text style={styles.eventDetail}>{item.detail}</Text>
          </View>
        </View>
      ))}
      <AdSlot surface="history" />
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
  summary: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  summaryItem: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flex: 1,
    minHeight: 72,
    padding: spacing.sm,
  },
  summaryNumber: {
    color: colors.ink,
    fontSize: 20,
    fontWeight: '900',
  },
  summaryLabel: {
    color: colors.muted,
    fontSize: 12,
    marginTop: 2,
  },
  event: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    gap: spacing.md,
  },
  time: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '900',
    width: 48,
  },
  eventBody: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: radii.md,
    borderWidth: 1,
    flex: 1,
    padding: spacing.md,
  },
  eventTitle: {
    color: colors.ink,
    fontSize: 15,
    fontWeight: '900',
  },
  eventDetail: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 3,
  },
});
