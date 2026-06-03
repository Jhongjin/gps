import React from 'react';
import { Pressable, StyleSheet, Text, ViewStyle } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { colors, radii, spacing } from '../theme/tokens';

type Props = {
  icon: keyof typeof MaterialCommunityIcons.glyphMap;
  label?: string;
  active?: boolean;
  accessibilityLabel: string;
  onPress: () => void;
  style?: ViewStyle;
};

export function IconButton({ icon, label, active = false, accessibilityLabel, onPress, style }: Props) {
  return (
    <Pressable
      accessibilityLabel={accessibilityLabel}
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        active && styles.active,
        pressed && styles.pressed,
        style,
      ]}
    >
      <MaterialCommunityIcons
        color={active ? colors.primary : colors.muted}
        name={icon}
        size={24}
      />
      {label ? <Text style={[styles.label, active && styles.activeLabel]}>{label}</Text> : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    alignItems: 'center',
    borderRadius: radii.md,
    gap: 4,
    justifyContent: 'center',
    minHeight: 44,
    minWidth: 48,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
  },
  active: {
    backgroundColor: colors.primarySoft,
  },
  pressed: {
    opacity: 0.72,
  },
  label: {
    color: colors.muted,
    fontSize: 11,
    fontWeight: '700',
  },
  activeLabel: {
    color: colors.primary,
  },
});

