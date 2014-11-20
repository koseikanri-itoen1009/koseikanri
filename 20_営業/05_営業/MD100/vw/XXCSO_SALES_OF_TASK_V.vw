/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_of_task_v
 * Description     : ���ʗp�F�L���K��̔����уr���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/11/24    1.0  D.Abe        ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_of_task_v
(
 account_number
,order_no_hht
,cancel_correct_class
,delivery_date
,change_out_time_100
,change_out_time_10
,delivery_pattern_class
,pure_amount
,sold_out_class
,sold_out_time
,dlv_invoice_number
,digestion_ln_number
)
AS
SELECT  seh.ship_to_customer_code      -- �ڋq�y�[�i��z
       ,seh.order_no_hht               -- ��No(HHT)
       ,seh.cancel_correct_class       -- ����E�����敪
       ,seh.delivery_date              -- �[�i��
       ,seh.change_out_time_100        -- ��K�؂ꎞ�ԂP�O�O�~
       ,seh.change_out_time_10         -- ��K�؂ꎞ�ԂP�O�~
       ,sel.delivery_pattern_class     -- �[�i�`�ԋ敪
       ,sel.pure_amount                -- �{�̋��z�i���ׁj
       ,sel.sold_out_class             -- ���؋敪
       ,sel.sold_out_time              -- ���؎���
       ,seh.dlv_invoice_number         -- �[�i�`�[�ԍ�
       ,seh.digestion_ln_number        -- ��No�iHHT�j�}��
FROM    xxcos_sales_exp_headers seh -- �̔����уw�b�_�[
       ,xxcos_sales_exp_lines   sel -- �̔����і���
WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id  -- �̔����уw�b�_ID
AND    NOT EXISTS
       ( -- �i�ڃR�[�h<>�ϓ��d�C���i�ڃR�[�h
         SELECT 'X'
         FROM   DUAL
         WHERE  sel.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_OF_TASK_V IS '���ʗp�F�L���K��̔����уr���[';

