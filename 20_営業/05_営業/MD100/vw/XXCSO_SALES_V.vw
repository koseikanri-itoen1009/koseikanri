/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_v
 * Description     : ���ʗp�F������уr���[
 * MD.070          : 
 * Version         : 1.2
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2009/03/03    1.1  K.Boku        ������ѐU�֏��e�[�u���擾����
 *  2009/03/09    1.1  M.Maruyama    �̔����уw�b�_.����E�����敪�ǉ�
 *  2009/04/22    1.2  K.Satomura    �V�X�e���e�X�g��Q�Ή�(T1_0743)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_v
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
/* 2009.04.22 K.Satomura T1_0743�Ή� START */
,dlv_invoice_number
/* 2009.04.22 K.Satomura T1_0743�Ή� END */
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
       /* 2009.04.22 K.Satomura T1_0743�Ή� START */
       ,seh.dlv_invoice_number         -- �[�i�`�[�ԍ�
       /* 2009.04.22 K.Satomura T1_0743�Ή� END */
FROM    xxcos_sales_exp_headers  seh   -- �̔����уw�b�_�[
       ,xxcos_sales_exp_lines  sel     -- �̔����і���
WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id  -- �̔����уw�b�_ID
AND    NOT EXISTS
       ( -- �i�ڃR�[�h<>�ϓ��d�C���i�ڃR�[�h
         SELECT 'X'
         FROM   DUAL
         WHERE  sel.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
UNION ALL
SELECT  xsti.cust_code                 -- �ڋq�R�[�h
       ,NULL                           -- 
       ,NULL                           -- 
       ,xsti.selling_date              -- ����v���
       ,NULL                           --
       ,NULL                           --
       ,xsti.delivery_form_type        -- �[�i�`�ԋ敪
       ,xsti.selling_amt_no_tax        -- ������z�i�Ŕ����j
       ,NULL                           --
       ,NULL                           --
       /* 2009.04.22 K.Satomura T1_0743�Ή� START */
       ,NULL                           -- �[�i�`�[�ԍ�
       /* 2009.04.22 K.Satomura T1_0743�Ή� END */
FROM    xxcok_selling_trns_info xsti   -- ������ѐU�֏��e�[�u��
WHERE  NOT EXISTS 
       ( -- �i�ڃR�[�h<>�ϓ��d�C���i�ڃR�[�h
         SELECT 'X'
         FROM   DUAL
         WHERE  xsti.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_V IS '���ʗp�F������уr���[';

