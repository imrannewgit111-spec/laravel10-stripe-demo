@extends('layouts.app')
@section('content')
<div class="container">
  <h1>{{ $product->title }}</h1>
  <p>{{ $product->description }}</p>
  <p class="fw-bold">₹{{ number_format($product->price_inr, 2) }}</p>
  <a href="{{ route('checkout.create', $product) }}" class="btn btn-primary">Proceed to Checkout</a>
  <a href="{{ route('products.index') }}" class="btn btn-link">Back</a>
</div>
@endsection
