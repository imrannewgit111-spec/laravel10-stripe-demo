@extends('layouts.app')
@section('content')
<div class="container">
  <div class="alert alert-warning">Payment cancelled. Try again.</div>
  <a class="btn btn-primary" href="{{ route('products.index') }}">Back</a>
</div>
@endsection
