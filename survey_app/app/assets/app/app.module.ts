import './rxjs-extensions';

import { NgModule }      from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule }   from '@angular/forms';
import { HttpModule }    from '@angular/http';

import { AppRoutingModule } from './app-routing.module';

import { AppComponent }         from './app.component';
import { DashboardComponent }   from './dashboard/dashboard.component';
import { CommonModule } from '@angular/common';
import {ReviewService} from "./review/review.service";
import {ReviewComponent} from "./review/review.component";

@NgModule({
  imports: [
    BrowserModule,
    FormsModule,
    HttpModule,
    AppRoutingModule,
    CommonModule,
  ],
  declarations: [
    AppComponent,
    DashboardComponent,
    ReviewComponent,

  ],
  providers: [
    ReviewService
  ],
  bootstrap: [ AppComponent ],
})
export class AppModule { }
