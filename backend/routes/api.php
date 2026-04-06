<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

Route::post('/auth/sync', [AuthController::class, 'sync']);
Route::get('/auth/profile/{firebaseUid}', [AuthController::class, 'profile']);