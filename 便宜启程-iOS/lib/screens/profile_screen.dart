import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/task_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Text('我的', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 4),
        Text(
          '今天是 ${tasks.today.month} 月 ${tasks.today.day} 日，每一步都算数',
          style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: [
              ProgressRing(
                progress: tasks.todayProgress.rate,
                size: 92,
                stroke: 8,
                child: Text(
                  '${tasks.todayProgress.percent}%',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今日完成率', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                    const SizedBox(height: 4),
                    Text(
                      '${tasks.todayProgress.done} / ${tasks.todayProgress.total} 已完成',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 10),
                    GlowBar(progress: tasks.todayProgress.rate),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _PeriodCard(title: '本周', progress: tasks.weekProgress)),
            const SizedBox(width: 12),
            Expanded(child: _PeriodCard(title: '本月', progress: tasks.monthProgress)),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('打卡天数', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${tasks.checkins.totalDays}',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: SpaceColors.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('天', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('连续打卡', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${tasks.checkins.streak}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: SpaceColors.accentSoft,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('天', style: TextStyle(fontSize: 13, color: SpaceColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '当天任务全部完成记 1 次打卡；没有任务的日子不影响连续。',
                style: TextStyle(fontSize: 11, color: SpaceColors.muted),
              ),
            ],
          ),
        ),
        const SectionTitle('小提示'),
        const GlassCard(
          child: Text(
            '完成率按“当天存在的任务”计算：一次性任务只在指定日期计入；删除的任务不会改写过去的记录。',
            style: TextStyle(fontSize: 12, height: 1.6, color: SpaceColors.muted),
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.title, required this.progress});
  final String title;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: SpaceColors.muted)),
          const SizedBox(height: 8),
          Text(
            '${progress.percent}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.done} / ${progress.total}',
            style: const TextStyle(fontSize: 11, color: SpaceColors.muted),
          ),
          const SizedBox(height: 10),
          GlowBar(progress: progress.rate),
        ],
      ),
    );
  }
}
