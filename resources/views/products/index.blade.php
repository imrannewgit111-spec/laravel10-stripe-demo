@extends('layouts.app')
@section('content')
<div class="container">
  <h1 class="mb-3">Products</h1>
  <div class="row">
    @foreach($products as $product)
      <div class="col-md-4">
        <div class="card mb-3">
          <div class="card-body">
            <h5 class="card-title">{{ $product->title }}</h5>
            <p class="card-text">{{ $product->description }}</p>
            <p class="fw-bold">₹{{ number_format($product->price_inr, 2) }}</p>
            <a href="{{ route('products.show', $product) }}" class="btn btn-outline-primary btn-sm">View</a>
            <a href="{{ route('checkout.create', $product) }}" class="btn btn-primary btn-sm">Buy</a>
          </div>
        </div>
      </div>
    @endforeach
  </div>
  {{ $products->links() }}
</div>
@endsection
