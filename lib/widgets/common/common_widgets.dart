import 'package:flutter/material.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/utils/utils.dart';

// Loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSizes.padding),
            Text(
              message!,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Custom button widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final button = isOutlined
        ? OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (icon != null ? Icon(icon) : const SizedBox.shrink()),
            label: Text(text),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor ?? AppColors.primary,
              side: BorderSide(color: backgroundColor ?? AppColors.primary),
              minimumSize: Size(width ?? double.infinity, height ?? 50),
            ),
          )
        : ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : (icon != null ? Icon(icon) : const SizedBox.shrink()),
            label: Text(text),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.primary,
              foregroundColor: textColor ?? Colors.white,
              minimumSize: Size(width ?? double.infinity, height ?? 50),
            ),
          );

    return SizedBox(
      width: width,
      height: height,
      child: button,
    );
  }
}

// Avatar widget
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Utils.generateColor(name),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        Utils.getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Custom text field widget
class CustomTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final int? maxLines;
  final bool enabled;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.padding),
      ),
    );
  }
}

// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: AppSizes.padding),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              message,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.onBackground.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSizes.paddingLarge),
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Error state widget
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.actionText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: AppSizes.padding),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              message,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.paddingLarge),
              CustomButton(
                text: actionText ?? 'Retry',
                onPressed: onRetry,
                width: 150,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom card widget
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.backgroundColor,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      elevation: elevation ?? AppSizes.elevation,
      color: backgroundColor ?? color,
      margin: margin ?? const EdgeInsets.all(AppSizes.paddingSmall),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSizes.padding),
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: card,
      );
    }

    return card;
  }
}

// Price change indicator widget
class PriceChangeIndicator extends StatelessWidget {
  final double change;
  final double percentage;
  final bool showIcon;
  final bool showPercentage;
  final TextStyle? textStyle;

  const PriceChangeIndicator({
    super.key,
    required this.change,
    required this.percentage,
    this.showIcon = true,
    this.showPercentage = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Utils.getPriceChangeColor(change);
    final icon = Utils.getPriceChangeIcon(change);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          Utils.formatCurrency(change.abs()),
          style: (textStyle ?? AppTextStyles.body2).copyWith(color: color),
        ),
        if (showPercentage) ...[
          const SizedBox(width: 4),
          Text(
            '(${Utils.formatPercentage(percentage)})',
            style: (textStyle ?? AppTextStyles.body2).copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

// Shimmer loading effect
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: const [
                Colors.grey,
                Colors.white,
                Colors.grey,
              ],
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Trending icon widget
class TrendingIcon extends StatelessWidget {
  final double change;
  final double size;

  const TrendingIcon({
    super.key,
    required this.change,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (change > 0) {
      icon = Icons.trending_up;
      color = AppColors.success;
    } else if (change < 0) {
      icon = Icons.trending_down;
      color = AppColors.error;
    } else {
      icon = Icons.trending_flat;
      color = AppColors.neutral;
    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
