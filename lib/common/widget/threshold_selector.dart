import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntodotxt/filter/model/filter_model.dart' show ListThreshold;
import 'package:ntodotxt/filter/state/filter_cubit.dart';
import 'package:ntodotxt/filter/state/filter_state.dart';

class ThresholdSelector extends StatelessWidget {
  final Set<ListThreshold> items;

  ThresholdSelector({super.key}) : items = ListThreshold.values.toSet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      buildWhen: (FilterState previousState, FilterState state) =>
          previousState.filter.threshold != state.filter.threshold,
      builder: (BuildContext context, FilterState state) {
        return Wrap(
          spacing: 4.0,
          alignment: WrapAlignment.start,
          runSpacing: 4.0,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (var i in items)
              ChoiceChip(
                label: Text(i.name),
                selected: state.filter.threshold == i,
                showCheckmark: false,
                visualDensity: const VisualDensity(
                  horizontal: -4.0,
                  vertical: -4.0,
                ),
                onSelected: (bool selected) =>
                    context.read<FilterCubit>().updateThreshold(i),
              ),
          ],
        );
      },
    );
  }
}
