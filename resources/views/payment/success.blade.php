@extends('layouts.app')
@section('content')
<div class="container">
  <div class="alert alert-success">Payment successful! 🎉 (Test mode)</div>
  <a class="btn btn-success" href="{{ route('products.index') }}">Continue</a>
</div>
@endsection
