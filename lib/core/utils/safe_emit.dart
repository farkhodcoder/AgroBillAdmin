import 'package:bloc/bloc.dart';

/// Yopilgan Cubit'ga `emit` ni jimgina tashlab yuboradi.
///
/// Sahifa Cubit'lari `BlocProvider` bilan sahifaga bog'langan: admin so'rov
/// tugamasdan boshqa bo'limga o'tsa, Cubit yopiladi, javob esa keyin keladi.
/// `bloc` 9 da yopilgandan keyingi `emit` `StateError` tashlaydi — konsolda
/// xato chiqib, `Future` zanjiri uzilardi. Har bir `await` dan keyin
/// `isClosed` ni qo'lda tekshirish oson unutiladi, shuning uchun bitta joyda.
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
