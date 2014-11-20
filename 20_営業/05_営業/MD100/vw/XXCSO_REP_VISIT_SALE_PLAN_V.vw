CREATE OR REPLACE view apps.xxcso_rep_visit_sale_plan_v AS
/*************************************************************************
 * 
 * VIEW Name       : xxcso_rep_visit_sale_plan_v
 * Description     : ’ •[—pF–K–â”„ãŒv‰æŠÇ—•\’ •[—pƒrƒ…[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/26    1.0  T.Maruyama    ‰‰ñì¬
 ************************************************************************/
SELECT  --ƒwƒbƒ_•”
        k1.request_id           request_id
       ,k1.report_id            k1_report_id
       ,k1.report_output_no     k1_report_output_no  --ƒuƒŒƒCƒNƒL[
       ,k1.report_name          k1_report_name
       ,to_char(k1.output_date,'yyyy/mm/dd')     k1_output_date_d
       ,to_char(k1.output_date,'hh24:mi:ss')     k1_output_date_h
       ,to_char(k1.year_month,'yyyymmdd')        k1_year_month
       ,k1.operation_days       k1_operation_days
       ,k1.operation_all_days   k1_operation_all_days
       --”„ã–¾×•”
       ,k2.line_kind k2_line_kind
       ,k2.line_num  k2_line_num
       ,k2.up_base_code k2_up_base_code
       ,k2.up_hub_name k2_up_hub_name
       ,k2.base_code k2_base_code
       ,k2.hub_name k2_hub_name
       ,k2.group_number k2_group_number
       ,k2.group_name k2_group_name
       ,k2.employee_number k2_employee_number
       ,k2.employee_name k2_employee_name
       ,k2.business_high_type k2_business_high_type
       ,k2.business_high_name k2_business_high_name
       ,k2.gvm_type k2_gvm_type
       ,k2.account_number k2_account_number
       ,k2.customer_name k2_customer_name
       ,k2.route_no k2_route_no
       ,k2.last_year_rslt_sales_amt k2_last_year_rslt_sales_amt
       ,k2.last_mon_rslt_sales_amt k2_last_mon_rslt_sales_amt
       ,k2.new_customer_num k2_new_customer_num
       ,k2.new_vendor_num k2_new_vendor_num
       ,k2.new_customer_amt k2_new_customer_amt
       ,k2.new_vendor_amt k2_new_vendor_amt
       ,k2.plan_sales_amt k2_plan_sales_amt
       ,k2.plan_vs_amt_1 k2_plan_vs_amt_1
       ,k2.rslt_vs_amt_1 k2_rslt_vs_amt_1
       ,k2.rslt_other_sales_amt_1 k2_rslt_other_sales_amt_1
       ,k2.visit_sign_1 k2_visit_sign_1
       ,k2.plan_vs_amt_2 k2_plan_vs_amt_2
       ,k2.rslt_vs_amt_2 k2_rslt_vs_amt_2
       ,k2.rslt_other_sales_amt_2 k2_rslt_other_sales_amt_2
       ,k2.visit_sign_2 k2_visit_sign_2
       ,k2.plan_vs_amt_3 k2_plan_vs_amt_3
       ,k2.rslt_vs_amt_3 k2_rslt_vs_amt_3
       ,k2.rslt_other_sales_amt_3 k2_rslt_other_sales_amt_3
       ,k2.visit_sign_3 k2_visit_sign_3
       ,k2.plan_vs_amt_4 k2_plan_vs_amt_4
       ,k2.rslt_vs_amt_4 k2_rslt_vs_amt_4
       ,k2.rslt_other_sales_amt_4 k2_rslt_other_sales_amt_4
       ,k2.visit_sign_4 k2_visit_sign_4
       ,k2.plan_vs_amt_5 k2_plan_vs_amt_5
       ,k2.rslt_vs_amt_5 k2_rslt_vs_amt_5
       ,k2.rslt_other_sales_amt_5 k2_rslt_other_sales_amt_5
       ,k2.visit_sign_5 k2_visit_sign_5
       ,k2.plan_vs_amt_6 k2_plan_vs_amt_6
       ,k2.rslt_vs_amt_6 k2_rslt_vs_amt_6
       ,k2.rslt_other_sales_amt_6 k2_rslt_other_sales_amt_6
       ,k2.visit_sign_6 k2_visit_sign_6
       ,k2.plan_vs_amt_7 k2_plan_vs_amt_7
       ,k2.rslt_vs_amt_7 k2_rslt_vs_amt_7
       ,k2.rslt_other_sales_amt_7 k2_rslt_other_sales_amt_7
       ,k2.visit_sign_7 k2_visit_sign_7
       ,k2.plan_vs_amt_8 k2_plan_vs_amt_8
       ,k2.rslt_vs_amt_8 k2_rslt_vs_amt_8
       ,k2.rslt_other_sales_amt_8 k2_rslt_other_sales_amt_8
       ,k2.visit_sign_8 k2_visit_sign_8
       ,k2.plan_vs_amt_9 k2_plan_vs_amt_9
       ,k2.rslt_vs_amt_9 k2_rslt_vs_amt_9
       ,k2.rslt_other_sales_amt_9 k2_rslt_other_sales_amt_9
       ,k2.visit_sign_9 k2_visit_sign_9
       ,k2.plan_vs_amt_10 k2_plan_vs_amt_10
       ,k2.rslt_vs_amt_10 k2_rslt_vs_amt_10
       ,k2.rslt_other_sales_amt_10 k2_rslt_other_sales_amt_10
       ,k2.visit_sign_10 k2_visit_sign_10
       ,k2.plan_vs_amt_11 k2_plan_vs_amt_11
       ,k2.rslt_vs_amt_11 k2_rslt_vs_amt_11
       ,k2.rslt_other_sales_amt_11 k2_rslt_other_sales_amt_11
       ,k2.visit_sign_11 k2_visit_sign_11
       ,k2.plan_vs_amt_12 k2_plan_vs_amt_12
       ,k2.rslt_vs_amt_12 k2_rslt_vs_amt_12
       ,k2.rslt_other_sales_amt_12 k2_rslt_other_sales_amt_12
       ,k2.visit_sign_12 k2_visit_sign_12
       ,k2.plan_vs_amt_13 k2_plan_vs_amt_13
       ,k2.rslt_vs_amt_13 k2_rslt_vs_amt_13
       ,k2.rslt_other_sales_amt_13 k2_rslt_other_sales_amt_13
       ,k2.visit_sign_13 k2_visit_sign_13
       ,k2.plan_vs_amt_14 k2_plan_vs_amt_14
       ,k2.rslt_vs_amt_14 k2_rslt_vs_amt_14
       ,k2.rslt_other_sales_amt_14 k2_rslt_other_sales_amt_14
       ,k2.visit_sign_14 k2_visit_sign_14
       ,k2.plan_vs_amt_15 k2_plan_vs_amt_15
       ,k2.rslt_vs_amt_15 k2_rslt_vs_amt_15
       ,k2.rslt_other_sales_amt_15 k2_rslt_other_sales_amt_15
       ,k2.visit_sign_15 k2_visit_sign_15
       ,k2.plan_vs_amt_16 k2_plan_vs_amt_16
       ,k2.rslt_vs_amt_16 k2_rslt_vs_amt_16
       ,k2.rslt_other_sales_amt_16 k2_rslt_other_sales_amt_16
       ,k2.visit_sign_16 k2_visit_sign_16
       ,k2.plan_vs_amt_17 k2_plan_vs_amt_17
       ,k2.rslt_vs_amt_17 k2_rslt_vs_amt_17
       ,k2.rslt_other_sales_amt_17 k2_rslt_other_sales_amt_17
       ,k2.visit_sign_17 k2_visit_sign_17
       ,k2.plan_vs_amt_18 k2_plan_vs_amt_18
       ,k2.rslt_vs_amt_18 k2_rslt_vs_amt_18
       ,k2.rslt_other_sales_amt_18 k2_rslt_other_sales_amt_18
       ,k2.visit_sign_18 k2_visit_sign_18
       ,k2.plan_vs_amt_19 k2_plan_vs_amt_19
       ,k2.rslt_vs_amt_19 k2_rslt_vs_amt_19
       ,k2.rslt_other_sales_amt_19 k2_rslt_other_sales_amt_19
       ,k2.visit_sign_19 k2_visit_sign_19
       ,k2.plan_vs_amt_20 k2_plan_vs_amt_20
       ,k2.rslt_vs_amt_20 k2_rslt_vs_amt_20
       ,k2.rslt_other_sales_amt_20 k2_rslt_other_sales_amt_20
       ,k2.visit_sign_20 k2_visit_sign_20
       ,k2.plan_vs_amt_21 k2_plan_vs_amt_21
       ,k2.rslt_vs_amt_21 k2_rslt_vs_amt_21
       ,k2.rslt_other_sales_amt_21 k2_rslt_other_sales_amt_21
       ,k2.visit_sign_21 k2_visit_sign_21
       ,k2.plan_vs_amt_22 k2_plan_vs_amt_22
       ,k2.rslt_vs_amt_22 k2_rslt_vs_amt_22
       ,k2.rslt_other_sales_amt_22 k2_rslt_other_sales_amt_22
       ,k2.visit_sign_22 k2_visit_sign_22
       ,k2.plan_vs_amt_23 k2_plan_vs_amt_23
       ,k2.rslt_vs_amt_23 k2_rslt_vs_amt_23
       ,k2.rslt_other_sales_amt_23 k2_rslt_other_sales_amt_23
       ,k2.visit_sign_23 k2_visit_sign_23
       ,k2.plan_vs_amt_24 k2_plan_vs_amt_24
       ,k2.rslt_vs_amt_24 k2_rslt_vs_amt_24
       ,k2.rslt_other_sales_amt_24 k2_rslt_other_sales_amt_24
       ,k2.visit_sign_24 k2_visit_sign_24
       ,k2.plan_vs_amt_25 k2_plan_vs_amt_25
       ,k2.rslt_vs_amt_25 k2_rslt_vs_amt_25
       ,k2.rslt_other_sales_amt_25 k2_rslt_other_sales_amt_25
       ,k2.visit_sign_25 k2_visit_sign_25
       ,k2.plan_vs_amt_26 k2_plan_vs_amt_26
       ,k2.rslt_vs_amt_26 k2_rslt_vs_amt_26
       ,k2.rslt_other_sales_amt_26 k2_rslt_other_sales_amt_26
       ,k2.visit_sign_26 k2_visit_sign_26
       ,k2.plan_vs_amt_27 k2_plan_vs_amt_27
       ,k2.rslt_vs_amt_27 k2_rslt_vs_amt_27
       ,k2.rslt_other_sales_amt_27 k2_rslt_other_sales_amt_27
       ,k2.visit_sign_27 k2_visit_sign_27
       ,k2.plan_vs_amt_28 k2_plan_vs_amt_28
       ,k2.rslt_vs_amt_28 k2_rslt_vs_amt_28
       ,k2.rslt_other_sales_amt_28 k2_rslt_other_sales_amt_28
       ,k2.visit_sign_28 k2_visit_sign_28
       ,k2.plan_vs_amt_29 k2_plan_vs_amt_29
       ,k2.rslt_vs_amt_29 k2_rslt_vs_amt_29
       ,k2.rslt_other_sales_amt_29 k2_rslt_other_sales_amt_29
       ,k2.visit_sign_29 k2_visit_sign_29
       ,k2.plan_vs_amt_30 k2_plan_vs_amt_30
       ,k2.rslt_vs_amt_30 k2_rslt_vs_amt_30
       ,k2.rslt_other_sales_amt_30 k2_rslt_other_sales_amt_30
       ,k2.visit_sign_30 k2_visit_sign_30
       ,k2.plan_vs_amt_31 k2_plan_vs_amt_31
       ,k2.rslt_vs_amt_31 k2_rslt_vs_amt_31
       ,k2.rslt_other_sales_amt_31 k2_rslt_other_sales_amt_31
       ,k2.visit_sign_31 k2_visit_sign_31
       --”„ã[’†Œv•”iˆê”Êj
       ,k3i.last_year_rslt_sales_amt k3i_last_year_rslt_sales_amt
       ,k3i.last_mon_rslt_sales_amt  k3i_last_mon_rslt_sales_amt
       ,k3i.new_customer_num         k3i_new_customer_num
       ,k3i.new_vendor_num           k3i_new_vendor_num
       ,k3i.new_customer_amt         k3i_new_customer_amt
       ,k3i.new_vendor_amt           k3i_new_vendor_amt
       ,k3i.plan_vs_amt_1 k3i_plan_vs_amt_1
       ,k3i.rslt_vs_amt_1 k3i_rslt_vs_amt_1
       ,k3i.rslt_other_sales_amt_1 k3i_rslt_other_sales_amt_1
       ,k3i.plan_vs_amt_2 k3i_plan_vs_amt_2
       ,k3i.rslt_vs_amt_2 k3i_rslt_vs_amt_2
       ,k3i.rslt_other_sales_amt_2 k3i_rslt_other_sales_amt_2
       ,k3i.plan_vs_amt_3 k3i_plan_vs_amt_3
       ,k3i.rslt_vs_amt_3 k3i_rslt_vs_amt_3
       ,k3i.rslt_other_sales_amt_3 k3i_rslt_other_sales_amt_3
       ,k3i.plan_vs_amt_4 k3i_plan_vs_amt_4
       ,k3i.rslt_vs_amt_4 k3i_rslt_vs_amt_4
       ,k3i.rslt_other_sales_amt_4 k3i_rslt_other_sales_amt_4
       ,k3i.plan_vs_amt_5 k3i_plan_vs_amt_5
       ,k3i.rslt_vs_amt_5 k3i_rslt_vs_amt_5
       ,k3i.rslt_other_sales_amt_5 k3i_rslt_other_sales_amt_5
       ,k3i.plan_vs_amt_6 k3i_plan_vs_amt_6
       ,k3i.rslt_vs_amt_6 k3i_rslt_vs_amt_6
       ,k3i.rslt_other_sales_amt_6 k3i_rslt_other_sales_amt_6
       ,k3i.plan_vs_amt_7 k3i_plan_vs_amt_7
       ,k3i.rslt_vs_amt_7 k3i_rslt_vs_amt_7
       ,k3i.rslt_other_sales_amt_7 k3i_rslt_other_sales_amt_7
       ,k3i.plan_vs_amt_8 k3i_plan_vs_amt_8
       ,k3i.rslt_vs_amt_8 k3i_rslt_vs_amt_8
       ,k3i.rslt_other_sales_amt_8 k3i_rslt_other_sales_amt_8
       ,k3i.plan_vs_amt_9 k3i_plan_vs_amt_9
       ,k3i.rslt_vs_amt_9 k3i_rslt_vs_amt_9
       ,k3i.rslt_other_sales_amt_9 k3i_rslt_other_sales_amt_9
       ,k3i.plan_vs_amt_10 k3i_plan_vs_amt_10
       ,k3i.rslt_vs_amt_10 k3i_rslt_vs_amt_10
       ,k3i.rslt_other_sales_amt_10 k3i_rslt_other_sales_amt_10
       ,k3i.plan_vs_amt_11 k3i_plan_vs_amt_11
       ,k3i.rslt_vs_amt_11 k3i_rslt_vs_amt_11
       ,k3i.rslt_other_sales_amt_11 k3i_rslt_other_sales_amt_11
       ,k3i.plan_vs_amt_12 k3i_plan_vs_amt_12
       ,k3i.rslt_vs_amt_12 k3i_rslt_vs_amt_12
       ,k3i.rslt_other_sales_amt_12 k3i_rslt_other_sales_amt_12
       ,k3i.plan_vs_amt_13 k3i_plan_vs_amt_13
       ,k3i.rslt_vs_amt_13 k3i_rslt_vs_amt_13
       ,k3i.rslt_other_sales_amt_13 k3i_rslt_other_sales_amt_13
       ,k3i.plan_vs_amt_14 k3i_plan_vs_amt_14
       ,k3i.rslt_vs_amt_14 k3i_rslt_vs_amt_14
       ,k3i.rslt_other_sales_amt_14 k3i_rslt_other_sales_amt_14
       ,k3i.plan_vs_amt_15 k3i_plan_vs_amt_15
       ,k3i.rslt_vs_amt_15 k3i_rslt_vs_amt_15
       ,k3i.rslt_other_sales_amt_15 k3i_rslt_other_sales_amt_15
       ,k3i.plan_vs_amt_16 k3i_plan_vs_amt_16
       ,k3i.rslt_vs_amt_16 k3i_rslt_vs_amt_16
       ,k3i.rslt_other_sales_amt_16 k3i_rslt_other_sales_amt_16
       ,k3i.plan_vs_amt_17 k3i_plan_vs_amt_17
       ,k3i.rslt_vs_amt_17 k3i_rslt_vs_amt_17
       ,k3i.rslt_other_sales_amt_17 k3i_rslt_other_sales_amt_17
       ,k3i.plan_vs_amt_18 k3i_plan_vs_amt_18
       ,k3i.rslt_vs_amt_18 k3i_rslt_vs_amt_18
       ,k3i.rslt_other_sales_amt_18 k3i_rslt_other_sales_amt_18
       ,k3i.plan_vs_amt_19 k3i_plan_vs_amt_19
       ,k3i.rslt_vs_amt_19 k3i_rslt_vs_amt_19
       ,k3i.rslt_other_sales_amt_19 k3i_rslt_other_sales_amt_19
       ,k3i.plan_vs_amt_20 k3i_plan_vs_amt_20
       ,k3i.rslt_vs_amt_20 k3i_rslt_vs_amt_20
       ,k3i.rslt_other_sales_amt_20 k3i_rslt_other_sales_amt_20
       ,k3i.plan_vs_amt_21 k3i_plan_vs_amt_21
       ,k3i.rslt_vs_amt_21 k3i_rslt_vs_amt_21
       ,k3i.rslt_other_sales_amt_21 k3i_rslt_other_sales_amt_21
       ,k3i.plan_vs_amt_22 k3i_plan_vs_amt_22
       ,k3i.rslt_vs_amt_22 k3i_rslt_vs_amt_22
       ,k3i.rslt_other_sales_amt_22 k3i_rslt_other_sales_amt_22
       ,k3i.plan_vs_amt_23 k3i_plan_vs_amt_23
       ,k3i.rslt_vs_amt_23 k3i_rslt_vs_amt_23
       ,k3i.rslt_other_sales_amt_23 k3i_rslt_other_sales_amt_23
       ,k3i.plan_vs_amt_24 k3i_plan_vs_amt_24
       ,k3i.rslt_vs_amt_24 k3i_rslt_vs_amt_24
       ,k3i.rslt_other_sales_amt_24 k3i_rslt_other_sales_amt_24
       ,k3i.plan_vs_amt_25 k3i_plan_vs_amt_25
       ,k3i.rslt_vs_amt_25 k3i_rslt_vs_amt_25
       ,k3i.rslt_other_sales_amt_25 k3i_rslt_other_sales_amt_25
       ,k3i.plan_vs_amt_26 k3i_plan_vs_amt_26
       ,k3i.rslt_vs_amt_26 k3i_rslt_vs_amt_26
       ,k3i.rslt_other_sales_amt_26 k3i_rslt_other_sales_amt_26
       ,k3i.plan_vs_amt_27 k3i_plan_vs_amt_27
       ,k3i.rslt_vs_amt_27 k3i_rslt_vs_amt_27
       ,k3i.rslt_other_sales_amt_27 k3i_rslt_other_sales_amt_27
       ,k3i.plan_vs_amt_28 k3i_plan_vs_amt_28
       ,k3i.rslt_vs_amt_28 k3i_rslt_vs_amt_28
       ,k3i.rslt_other_sales_amt_28 k3i_rslt_other_sales_amt_28
       ,k3i.plan_vs_amt_29 k3i_plan_vs_amt_29
       ,k3i.rslt_vs_amt_29 k3i_rslt_vs_amt_29
       ,k3i.rslt_other_sales_amt_29 k3i_rslt_other_sales_amt_29
       ,k3i.plan_vs_amt_30 k3i_plan_vs_amt_30
       ,k3i.rslt_vs_amt_30 k3i_rslt_vs_amt_30
       ,k3i.rslt_other_sales_amt_30 k3i_rslt_other_sales_amt_30
       ,k3i.plan_vs_amt_31 k3i_plan_vs_amt_31
       ,k3i.rslt_vs_amt_31 k3i_rslt_vs_amt_31
       ,k3i.rslt_other_sales_amt_31 k3i_rslt_other_sales_amt_31
       --”„ã[’†Œv•”i©”Ì‹@j
       ,k3v.last_year_rslt_sales_amt k3v_last_year_rslt_sales_amt
       ,k3v.last_mon_rslt_sales_amt  k3v_last_mon_rslt_sales_amt
       ,k3v.new_customer_num         k3v_new_customer_num
       ,k3v.new_vendor_num           k3v_new_vendor_num
       ,k3v.new_customer_amt         k3v_new_customer_amt
       ,k3v.new_vendor_amt           k3v_new_vendor_amt
       ,k3v.plan_vs_amt_1 k3v_plan_vs_amt_1
       ,k3v.rslt_vs_amt_1 k3v_rslt_vs_amt_1
       ,k3v.rslt_other_sales_amt_1 k3v_rslt_other_sales_amt_1
       ,k3v.plan_vs_amt_2 k3v_plan_vs_amt_2
       ,k3v.rslt_vs_amt_2 k3v_rslt_vs_amt_2
       ,k3v.rslt_other_sales_amt_2 k3v_rslt_other_sales_amt_2
       ,k3v.plan_vs_amt_3 k3v_plan_vs_amt_3
       ,k3v.rslt_vs_amt_3 k3v_rslt_vs_amt_3
       ,k3v.rslt_other_sales_amt_3 k3v_rslt_other_sales_amt_3
       ,k3v.plan_vs_amt_4 k3v_plan_vs_amt_4
       ,k3v.rslt_vs_amt_4 k3v_rslt_vs_amt_4
       ,k3v.rslt_other_sales_amt_4 k3v_rslt_other_sales_amt_4
       ,k3v.plan_vs_amt_5 k3v_plan_vs_amt_5
       ,k3v.rslt_vs_amt_5 k3v_rslt_vs_amt_5
       ,k3v.rslt_other_sales_amt_5 k3v_rslt_other_sales_amt_5
       ,k3v.plan_vs_amt_6 k3v_plan_vs_amt_6
       ,k3v.rslt_vs_amt_6 k3v_rslt_vs_amt_6
       ,k3v.rslt_other_sales_amt_6 k3v_rslt_other_sales_amt_6
       ,k3v.plan_vs_amt_7 k3v_plan_vs_amt_7
       ,k3v.rslt_vs_amt_7 k3v_rslt_vs_amt_7
       ,k3v.rslt_other_sales_amt_7 k3v_rslt_other_sales_amt_7
       ,k3v.plan_vs_amt_8 k3v_plan_vs_amt_8
       ,k3v.rslt_vs_amt_8 k3v_rslt_vs_amt_8
       ,k3v.rslt_other_sales_amt_8 k3v_rslt_other_sales_amt_8
       ,k3v.plan_vs_amt_9 k3v_plan_vs_amt_9
       ,k3v.rslt_vs_amt_9 k3v_rslt_vs_amt_9
       ,k3v.rslt_other_sales_amt_9 k3v_rslt_other_sales_amt_9
       ,k3v.plan_vs_amt_10 k3v_plan_vs_amt_10
       ,k3v.rslt_vs_amt_10 k3v_rslt_vs_amt_10
       ,k3v.rslt_other_sales_amt_10 k3v_rslt_other_sales_amt_10
       ,k3v.plan_vs_amt_11 k3v_plan_vs_amt_11
       ,k3v.rslt_vs_amt_11 k3v_rslt_vs_amt_11
       ,k3v.rslt_other_sales_amt_11 k3v_rslt_other_sales_amt_11
       ,k3v.plan_vs_amt_12 k3v_plan_vs_amt_12
       ,k3v.rslt_vs_amt_12 k3v_rslt_vs_amt_12
       ,k3v.rslt_other_sales_amt_12 k3v_rslt_other_sales_amt_12
       ,k3v.plan_vs_amt_13 k3v_plan_vs_amt_13
       ,k3v.rslt_vs_amt_13 k3v_rslt_vs_amt_13
       ,k3v.rslt_other_sales_amt_13 k3v_rslt_other_sales_amt_13
       ,k3v.plan_vs_amt_14 k3v_plan_vs_amt_14
       ,k3v.rslt_vs_amt_14 k3v_rslt_vs_amt_14
       ,k3v.rslt_other_sales_amt_14 k3v_rslt_other_sales_amt_14
       ,k3v.plan_vs_amt_15 k3v_plan_vs_amt_15
       ,k3v.rslt_vs_amt_15 k3v_rslt_vs_amt_15
       ,k3v.rslt_other_sales_amt_15 k3v_rslt_other_sales_amt_15
       ,k3v.plan_vs_amt_16 k3v_plan_vs_amt_16
       ,k3v.rslt_vs_amt_16 k3v_rslt_vs_amt_16
       ,k3v.rslt_other_sales_amt_16 k3v_rslt_other_sales_amt_16
       ,k3v.plan_vs_amt_17 k3v_plan_vs_amt_17
       ,k3v.rslt_vs_amt_17 k3v_rslt_vs_amt_17
       ,k3v.rslt_other_sales_amt_17 k3v_rslt_other_sales_amt_17
       ,k3v.plan_vs_amt_18 k3v_plan_vs_amt_18
       ,k3v.rslt_vs_amt_18 k3v_rslt_vs_amt_18
       ,k3v.rslt_other_sales_amt_18 k3v_rslt_other_sales_amt_18
       ,k3v.plan_vs_amt_19 k3v_plan_vs_amt_19
       ,k3v.rslt_vs_amt_19 k3v_rslt_vs_amt_19
       ,k3v.rslt_other_sales_amt_19 k3v_rslt_other_sales_amt_19
       ,k3v.plan_vs_amt_20 k3v_plan_vs_amt_20
       ,k3v.rslt_vs_amt_20 k3v_rslt_vs_amt_20
       ,k3v.rslt_other_sales_amt_20 k3v_rslt_other_sales_amt_20
       ,k3v.plan_vs_amt_21 k3v_plan_vs_amt_21
       ,k3v.rslt_vs_amt_21 k3v_rslt_vs_amt_21
       ,k3v.rslt_other_sales_amt_21 k3v_rslt_other_sales_amt_21
       ,k3v.plan_vs_amt_22 k3v_plan_vs_amt_22
       ,k3v.rslt_vs_amt_22 k3v_rslt_vs_amt_22
       ,k3v.rslt_other_sales_amt_22 k3v_rslt_other_sales_amt_22
       ,k3v.plan_vs_amt_23 k3v_plan_vs_amt_23
       ,k3v.rslt_vs_amt_23 k3v_rslt_vs_amt_23
       ,k3v.rslt_other_sales_amt_23 k3v_rslt_other_sales_amt_23
       ,k3v.plan_vs_amt_24 k3v_plan_vs_amt_24
       ,k3v.rslt_vs_amt_24 k3v_rslt_vs_amt_24
       ,k3v.rslt_other_sales_amt_24 k3v_rslt_other_sales_amt_24
       ,k3v.plan_vs_amt_25 k3v_plan_vs_amt_25
       ,k3v.rslt_vs_amt_25 k3v_rslt_vs_amt_25
       ,k3v.rslt_other_sales_amt_25 k3v_rslt_other_sales_amt_25
       ,k3v.plan_vs_amt_26 k3v_plan_vs_amt_26
       ,k3v.rslt_vs_amt_26 k3v_rslt_vs_amt_26
       ,k3v.rslt_other_sales_amt_26 k3v_rslt_other_sales_amt_26
       ,k3v.plan_vs_amt_27 k3v_plan_vs_amt_27
       ,k3v.rslt_vs_amt_27 k3v_rslt_vs_amt_27
       ,k3v.rslt_other_sales_amt_27 k3v_rslt_other_sales_amt_27
       ,k3v.plan_vs_amt_28 k3v_plan_vs_amt_28
       ,k3v.rslt_vs_amt_28 k3v_rslt_vs_amt_28
       ,k3v.rslt_other_sales_amt_28 k3v_rslt_other_sales_amt_28
       ,k3v.plan_vs_amt_29 k3v_plan_vs_amt_29
       ,k3v.rslt_vs_amt_29 k3v_rslt_vs_amt_29
       ,k3v.rslt_other_sales_amt_29 k3v_rslt_other_sales_amt_29
       ,k3v.plan_vs_amt_30 k3v_plan_vs_amt_30
       ,k3v.rslt_vs_amt_30 k3v_rslt_vs_amt_30
       ,k3v.rslt_other_sales_amt_30 k3v_rslt_other_sales_amt_30
       ,k3v.plan_vs_amt_31 k3v_plan_vs_amt_31
       ,k3v.rslt_vs_amt_31 k3v_rslt_vs_amt_31
       ,k3v.rslt_other_sales_amt_31 k3v_rslt_other_sales_amt_31
       --”„ã[‡Œv•”
       ,k4.new_customer_num k4_new_customer_num
       ,k4.new_vendor_num   k4_new_vendor_num
       ,k4.plan_sales_amt   k4_plan_sales_amt
       --–K–â[’†Œv•”iˆê”Êj
       ,k5i.plan_vs_amt_1 k5i_plan_vs_amt_1
       ,k5i.rslt_vs_amt_1 k5i_rslt_vs_amt_1
       ,k5i.plan_vs_amt_2 k5i_plan_vs_amt_2
       ,k5i.rslt_vs_amt_2 k5i_rslt_vs_amt_2
       ,k5i.plan_vs_amt_3 k5i_plan_vs_amt_3
       ,k5i.rslt_vs_amt_3 k5i_rslt_vs_amt_3
       ,k5i.plan_vs_amt_4 k5i_plan_vs_amt_4
       ,k5i.rslt_vs_amt_4 k5i_rslt_vs_amt_4
       ,k5i.plan_vs_amt_5 k5i_plan_vs_amt_5
       ,k5i.rslt_vs_amt_5 k5i_rslt_vs_amt_5
       ,k5i.plan_vs_amt_6 k5i_plan_vs_amt_6
       ,k5i.rslt_vs_amt_6 k5i_rslt_vs_amt_6
       ,k5i.plan_vs_amt_7 k5i_plan_vs_amt_7
       ,k5i.rslt_vs_amt_7 k5i_rslt_vs_amt_7
       ,k5i.plan_vs_amt_8 k5i_plan_vs_amt_8
       ,k5i.rslt_vs_amt_8 k5i_rslt_vs_amt_8
       ,k5i.plan_vs_amt_9 k5i_plan_vs_amt_9
       ,k5i.rslt_vs_amt_9 k5i_rslt_vs_amt_9
       ,k5i.plan_vs_amt_10 k5i_plan_vs_amt_10
       ,k5i.rslt_vs_amt_10 k5i_rslt_vs_amt_10
       ,k5i.plan_vs_amt_11 k5i_plan_vs_amt_11
       ,k5i.rslt_vs_amt_11 k5i_rslt_vs_amt_11
       ,k5i.plan_vs_amt_12 k5i_plan_vs_amt_12
       ,k5i.rslt_vs_amt_12 k5i_rslt_vs_amt_12
       ,k5i.plan_vs_amt_13 k5i_plan_vs_amt_13
       ,k5i.rslt_vs_amt_13 k5i_rslt_vs_amt_13
       ,k5i.plan_vs_amt_14 k5i_plan_vs_amt_14
       ,k5i.rslt_vs_amt_14 k5i_rslt_vs_amt_14
       ,k5i.plan_vs_amt_15 k5i_plan_vs_amt_15
       ,k5i.rslt_vs_amt_15 k5i_rslt_vs_amt_15
       ,k5i.plan_vs_amt_16 k5i_plan_vs_amt_16
       ,k5i.rslt_vs_amt_16 k5i_rslt_vs_amt_16
       ,k5i.plan_vs_amt_17 k5i_plan_vs_amt_17
       ,k5i.rslt_vs_amt_17 k5i_rslt_vs_amt_17
       ,k5i.plan_vs_amt_18 k5i_plan_vs_amt_18
       ,k5i.rslt_vs_amt_18 k5i_rslt_vs_amt_18
       ,k5i.plan_vs_amt_19 k5i_plan_vs_amt_19
       ,k5i.rslt_vs_amt_19 k5i_rslt_vs_amt_19
       ,k5i.plan_vs_amt_20 k5i_plan_vs_amt_20
       ,k5i.rslt_vs_amt_20 k5i_rslt_vs_amt_20
       ,k5i.plan_vs_amt_21 k5i_plan_vs_amt_21
       ,k5i.rslt_vs_amt_21 k5i_rslt_vs_amt_21
       ,k5i.plan_vs_amt_22 k5i_plan_vs_amt_22
       ,k5i.rslt_vs_amt_22 k5i_rslt_vs_amt_22
       ,k5i.plan_vs_amt_23 k5i_plan_vs_amt_23
       ,k5i.rslt_vs_amt_23 k5i_rslt_vs_amt_23
       ,k5i.plan_vs_amt_24 k5i_plan_vs_amt_24
       ,k5i.rslt_vs_amt_24 k5i_rslt_vs_amt_24
       ,k5i.plan_vs_amt_25 k5i_plan_vs_amt_25
       ,k5i.rslt_vs_amt_25 k5i_rslt_vs_amt_25
       ,k5i.plan_vs_amt_26 k5i_plan_vs_amt_26
       ,k5i.rslt_vs_amt_26 k5i_rslt_vs_amt_26
       ,k5i.plan_vs_amt_27 k5i_plan_vs_amt_27
       ,k5i.rslt_vs_amt_27 k5i_rslt_vs_amt_27
       ,k5i.plan_vs_amt_28 k5i_plan_vs_amt_28
       ,k5i.rslt_vs_amt_28 k5i_rslt_vs_amt_28
       ,k5i.plan_vs_amt_29 k5i_plan_vs_amt_29
       ,k5i.rslt_vs_amt_29 k5i_rslt_vs_amt_29
       ,k5i.plan_vs_amt_30 k5i_plan_vs_amt_30
       ,k5i.rslt_vs_amt_30 k5i_rslt_vs_amt_30
       ,k5i.plan_vs_amt_31 k5i_plan_vs_amt_31
       ,k5i.rslt_vs_amt_31 k5i_rslt_vs_amt_31
       --–K–â[’†Œv•”i©”Ì‹@j
       ,k5v.plan_vs_amt_1 k5v_plan_vs_amt_1
       ,k5v.rslt_vs_amt_1 k5v_rslt_vs_amt_1
       ,k5v.plan_vs_amt_2 k5v_plan_vs_amt_2
       ,k5v.rslt_vs_amt_2 k5v_rslt_vs_amt_2
       ,k5v.plan_vs_amt_3 k5v_plan_vs_amt_3
       ,k5v.rslt_vs_amt_3 k5v_rslt_vs_amt_3
       ,k5v.plan_vs_amt_4 k5v_plan_vs_amt_4
       ,k5v.rslt_vs_amt_4 k5v_rslt_vs_amt_4
       ,k5v.plan_vs_amt_5 k5v_plan_vs_amt_5
       ,k5v.rslt_vs_amt_5 k5v_rslt_vs_amt_5
       ,k5v.plan_vs_amt_6 k5v_plan_vs_amt_6
       ,k5v.rslt_vs_amt_6 k5v_rslt_vs_amt_6
       ,k5v.plan_vs_amt_7 k5v_plan_vs_amt_7
       ,k5v.rslt_vs_amt_7 k5v_rslt_vs_amt_7
       ,k5v.plan_vs_amt_8 k5v_plan_vs_amt_8
       ,k5v.rslt_vs_amt_8 k5v_rslt_vs_amt_8
       ,k5v.plan_vs_amt_9 k5v_plan_vs_amt_9
       ,k5v.rslt_vs_amt_9 k5v_rslt_vs_amt_9
       ,k5v.plan_vs_amt_10 k5v_plan_vs_amt_10
       ,k5v.rslt_vs_amt_10 k5v_rslt_vs_amt_10
       ,k5v.plan_vs_amt_11 k5v_plan_vs_amt_11
       ,k5v.rslt_vs_amt_11 k5v_rslt_vs_amt_11
       ,k5v.plan_vs_amt_12 k5v_plan_vs_amt_12
       ,k5v.rslt_vs_amt_12 k5v_rslt_vs_amt_12
       ,k5v.plan_vs_amt_13 k5v_plan_vs_amt_13
       ,k5v.rslt_vs_amt_13 k5v_rslt_vs_amt_13
       ,k5v.plan_vs_amt_14 k5v_plan_vs_amt_14
       ,k5v.rslt_vs_amt_14 k5v_rslt_vs_amt_14
       ,k5v.plan_vs_amt_15 k5v_plan_vs_amt_15
       ,k5v.rslt_vs_amt_15 k5v_rslt_vs_amt_15
       ,k5v.plan_vs_amt_16 k5v_plan_vs_amt_16
       ,k5v.rslt_vs_amt_16 k5v_rslt_vs_amt_16
       ,k5v.plan_vs_amt_17 k5v_plan_vs_amt_17
       ,k5v.rslt_vs_amt_17 k5v_rslt_vs_amt_17
       ,k5v.plan_vs_amt_18 k5v_plan_vs_amt_18
       ,k5v.rslt_vs_amt_18 k5v_rslt_vs_amt_18
       ,k5v.plan_vs_amt_19 k5v_plan_vs_amt_19
       ,k5v.rslt_vs_amt_19 k5v_rslt_vs_amt_19
       ,k5v.plan_vs_amt_20 k5v_plan_vs_amt_20
       ,k5v.rslt_vs_amt_20 k5v_rslt_vs_amt_20
       ,k5v.plan_vs_amt_21 k5v_plan_vs_amt_21
       ,k5v.rslt_vs_amt_21 k5v_rslt_vs_amt_21
       ,k5v.plan_vs_amt_22 k5v_plan_vs_amt_22
       ,k5v.rslt_vs_amt_22 k5v_rslt_vs_amt_22
       ,k5v.plan_vs_amt_23 k5v_plan_vs_amt_23
       ,k5v.rslt_vs_amt_23 k5v_rslt_vs_amt_23
       ,k5v.plan_vs_amt_24 k5v_plan_vs_amt_24
       ,k5v.rslt_vs_amt_24 k5v_rslt_vs_amt_24
       ,k5v.plan_vs_amt_25 k5v_plan_vs_amt_25
       ,k5v.rslt_vs_amt_25 k5v_rslt_vs_amt_25
       ,k5v.plan_vs_amt_26 k5v_plan_vs_amt_26
       ,k5v.rslt_vs_amt_26 k5v_rslt_vs_amt_26
       ,k5v.plan_vs_amt_27 k5v_plan_vs_amt_27
       ,k5v.rslt_vs_amt_27 k5v_rslt_vs_amt_27
       ,k5v.plan_vs_amt_28 k5v_plan_vs_amt_28
       ,k5v.rslt_vs_amt_28 k5v_rslt_vs_amt_28
       ,k5v.plan_vs_amt_29 k5v_plan_vs_amt_29
       ,k5v.rslt_vs_amt_29 k5v_rslt_vs_amt_29
       ,k5v.plan_vs_amt_30 k5v_plan_vs_amt_30
       ,k5v.rslt_vs_amt_30 k5v_rslt_vs_amt_30
       ,k5v.plan_vs_amt_31 k5v_plan_vs_amt_31
       ,k5v.rslt_vs_amt_31 k5v_rslt_vs_amt_31
       --–K–â[’†Œv•”i‚‚ƒj
       ,k5m.rslt_vs_amt_1 k5m_rslt_vs_amt_1
       ,k5m.rslt_vs_amt_2 k5m_rslt_vs_amt_2
       ,k5m.rslt_vs_amt_3 k5m_rslt_vs_amt_3
       ,k5m.rslt_vs_amt_4 k5m_rslt_vs_amt_4
       ,k5m.rslt_vs_amt_5 k5m_rslt_vs_amt_5
       ,k5m.rslt_vs_amt_6 k5m_rslt_vs_amt_6
       ,k5m.rslt_vs_amt_7 k5m_rslt_vs_amt_7
       ,k5m.rslt_vs_amt_8 k5m_rslt_vs_amt_8
       ,k5m.rslt_vs_amt_9 k5m_rslt_vs_amt_9
       ,k5m.rslt_vs_amt_10 k5m_rslt_vs_amt_10
       ,k5m.rslt_vs_amt_11 k5m_rslt_vs_amt_11
       ,k5m.rslt_vs_amt_12 k5m_rslt_vs_amt_12
       ,k5m.rslt_vs_amt_13 k5m_rslt_vs_amt_13
       ,k5m.rslt_vs_amt_14 k5m_rslt_vs_amt_14
       ,k5m.rslt_vs_amt_15 k5m_rslt_vs_amt_15
       ,k5m.rslt_vs_amt_16 k5m_rslt_vs_amt_16
       ,k5m.rslt_vs_amt_17 k5m_rslt_vs_amt_17
       ,k5m.rslt_vs_amt_18 k5m_rslt_vs_amt_18
       ,k5m.rslt_vs_amt_19 k5m_rslt_vs_amt_19
       ,k5m.rslt_vs_amt_20 k5m_rslt_vs_amt_20
       ,k5m.rslt_vs_amt_21 k5m_rslt_vs_amt_21
       ,k5m.rslt_vs_amt_22 k5m_rslt_vs_amt_22
       ,k5m.rslt_vs_amt_23 k5m_rslt_vs_amt_23
       ,k5m.rslt_vs_amt_24 k5m_rslt_vs_amt_24
       ,k5m.rslt_vs_amt_25 k5m_rslt_vs_amt_25
       ,k5m.rslt_vs_amt_26 k5m_rslt_vs_amt_26
       ,k5m.rslt_vs_amt_27 k5m_rslt_vs_amt_27
       ,k5m.rslt_vs_amt_28 k5m_rslt_vs_amt_28
       ,k5m.rslt_vs_amt_29 k5m_rslt_vs_amt_29
       ,k5m.rslt_vs_amt_30 k5m_rslt_vs_amt_30
       ,k5m.rslt_vs_amt_31 k5m_rslt_vs_amt_31
      --–K–â[‡Œv•”
       ,k6.effective_num_1 k6_effective_num_1
       ,k6.effective_num_2 k6_effective_num_2
       ,k6.effective_num_3 k6_effective_num_3
       ,k6.effective_num_4 k6_effective_num_4
       ,k6.effective_num_5 k6_effective_num_5
       ,k6.effective_num_6 k6_effective_num_6
       ,k6.effective_num_7 k6_effective_num_7
       ,k6.effective_num_8 k6_effective_num_8
       ,k6.effective_num_9 k6_effective_num_9
       ,k6.effective_num_10 k6_effective_num_10
       ,k6.effective_num_11 k6_effective_num_11
       ,k6.effective_num_12 k6_effective_num_12
       ,k6.effective_num_13 k6_effective_num_13
       ,k6.effective_num_14 k6_effective_num_14
       ,k6.effective_num_15 k6_effective_num_15
       ,k6.effective_num_16 k6_effective_num_16
       ,k6.effective_num_17 k6_effective_num_17
       ,k6.effective_num_18 k6_effective_num_18
       ,k6.effective_num_19 k6_effective_num_19
       ,k6.effective_num_20 k6_effective_num_20
       ,k6.effective_num_21 k6_effective_num_21
       ,k6.effective_num_22 k6_effective_num_22
       ,k6.effective_num_23 k6_effective_num_23
       ,k6.effective_num_24 k6_effective_num_24
       ,k6.effective_num_25 k6_effective_num_25
       ,k6.effective_num_26 k6_effective_num_26
       ,k6.effective_num_27 k6_effective_num_27
       ,k6.effective_num_28 k6_effective_num_28
       ,k6.effective_num_29 k6_effective_num_29
       ,k6.effective_num_30 k6_effective_num_30
       ,k6.effective_num_31 k6_effective_num_31
       --–K–â“à—e[–¾×•”
       ,k7.vis_a_num k7_vis_a_num
       ,k7.vis_b_num k7_vis_b_num
       ,k7.vis_c_num k7_vis_c_num
       ,k7.vis_d_num k7_vis_d_num
       ,k7.vis_e_num k7_vis_e_num
       ,k7.vis_f_num k7_vis_f_num
       ,k7.vis_g_num k7_vis_g_num
       ,k7.vis_h_num k7_vis_h_num
       ,k7.vis_i_num k7_vis_i_num
       ,k7.vis_j_num k7_vis_j_num
       ,k7.vis_k_num k7_vis_k_num
       ,k7.vis_l_num k7_vis_l_num
       ,k7.vis_m_num k7_vis_m_num
       ,k7.vis_n_num k7_vis_n_num
       ,k7.vis_o_num k7_vis_o_num
       ,k7.vis_p_num k7_vis_p_num
       ,k7.vis_q_num k7_vis_q_num
       ,k7.vis_r_num k7_vis_r_num
       ,k7.vis_s_num k7_vis_s_num
       ,k7.vis_t_num k7_vis_t_num
       ,k7.vis_u_num k7_vis_u_num
       ,k7.vis_v_num k7_vis_v_num
       ,k7.vis_w_num k7_vis_w_num
       ,k7.vis_x_num k7_vis_x_num
       ,k7.vis_y_num k7_vis_y_num
       ,k7.vis_z_num k7_vis_z_num
FROM   xxcso_rep_visit_sale_plan k1,    --‚P:‚PFƒwƒbƒ_[•”
       xxcso_rep_visit_sale_plan k2,    --‚QF‚QF”„ã|–¾×•”
       xxcso_rep_visit_sale_plan k3i,   --‚RF‚RF”„ã|’†Œv•”iˆê”Êj
       xxcso_rep_visit_sale_plan k3v,   --‚SF‚RF”„ã|’†Œv•”i©”Ì‹@j
       xxcso_rep_visit_sale_plan k4,    --‚TF‚SF”„ã|‡Œv•”
       xxcso_rep_visit_sale_plan k5i,   --‚UF‚TF–K–â|’†Œv•”iˆê”Êj
       xxcso_rep_visit_sale_plan k5v,   --‚VF‚TF–K–â|’†Œv•”i©”Ì‹@j
       xxcso_rep_visit_sale_plan k5m,   --‚WF‚TF–K–â|’†Œv•”iMCj
       xxcso_rep_visit_sale_plan k6,    --‚XF‚UF–K–â|‡Œv•”
       xxcso_rep_visit_sale_plan k7     --‚P‚OF‚VF–K–â“à—e|–¾×•”
WHERE  k1.request_id = k2.request_id
AND    k1.request_id = k3i.request_id
AND    k1.request_id = k3v.request_id
AND    k1.request_id = k4.request_id
AND    k1.request_id = k5i.request_id
AND    k1.request_id = k5v.request_id
AND    k1.request_id = k5m.request_id
AND    k1.request_id = k6.request_id
AND    k1.request_id = k7.request_id
AND    k1.report_output_no = k2.report_output_no
AND    k1.report_output_no = k3i.report_output_no
AND    k1.report_output_no = k3v.report_output_no
AND    k1.report_output_no = k4.report_output_no
AND    k1.report_output_no = k5i.report_output_no
AND    k1.report_output_no = k5v.report_output_no
AND    k1.report_output_no = k5m.report_output_no
AND    k1.report_output_no = k6.report_output_no
AND    k1.report_output_no = k7.report_output_no
AND    k1.line_kind   =  1   -- ƒwƒbƒ_[•”
AND    k2.line_kind   =  2   -- ”„ã|–¾×•”
AND   (k3i.line_kind  =  3 
AND    k3i.gvm_type   = '1') -- ”„ã|’†Œv•”iˆê”Êj
AND   (k3v.line_kind  =  3
AND    k3v.gvm_type   = '2') -- ”„ã|’†Œv•”i©”Ì‹@j
AND    k4.line_kind   =  4
AND   (k5i.line_kind  =  5
AND    k5i.gvm_type   = '1') -- –K–â|’†Œv•”iˆê”Êj
AND   (k5v.line_kind  =  5
AND    k5v.gvm_type   = '2') -- –K–â|’†Œv•”i©”Ì‹@j
AND   (k5m.line_kind  =  5
AND    k5m.gvm_type   = '3') -- –K–â|’†Œv•”iMCj
AND    k6.line_kind   =  6   -- –K–â|‡Œv•”
AND    k7.line_kind   =  7   -- –K–â“à—e|–¾×•”
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_REP_VISIT_SALE_PLAN_V IS '’ •[—pF–K–â”„ãŒv‰æŠÇ—•\’ •[—pƒrƒ…[';

