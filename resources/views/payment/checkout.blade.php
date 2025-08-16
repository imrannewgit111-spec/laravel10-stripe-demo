@extends('layouts.app')
@section('content')
<div class="container">
  <h1 class="mb-3">Checkout — {{ $product->title }}</h1>
  <p>Amount: <strong>₹{{ number_format($product->price_inr, 2) }}</strong></p>
  <form method="POST" action="{{ route('checkout.start', $product) }}">
    @csrf
    <button class="btn btn-primary">Pay with Stripe</button>
  </form>
  <p class="mt-3 text-muted">Test card: 4242 4242 4242 4242 (any future expiry, any CVC)</p>
</div>
@endsection
