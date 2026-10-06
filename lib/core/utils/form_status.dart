/// Lifecycle of a form submission, shared by the form cubits.
enum FormStatus {
  idle,
  submitting,
  success,
  failure;

  bool get isSubmitting => this == submitting;
}
