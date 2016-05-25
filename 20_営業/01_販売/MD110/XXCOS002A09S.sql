SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

clear buffer;

set feed off
set linesize 300
set pagesize 5000
set underline '='
set serveroutput on size 1000000
set trimspool on

set head off

------------���^�C�g���s��
SELECT
         '���㋒�_�R�[�h'
  ||','||'���_��'
  ||','||'�[�i�҃R�[�h'
  ||','||'�[�i�Җ�'
  ||','||'�[�i��'
  ||','||'�ڋq�R�[�h'
  ||','||'�ڋq��'
  ||','||'�[�i�`�[�ԍ�'
  ||','||'�J�[�h���敪'
  ||','||'�i�`�[�j������z'
  ||','||'�i�`�[�j�����J�[�h���p�z'
  ||','||'�iVD�j��������g�[�^���̔����z'
  ||','||'�iVD�j�J�[�h�g�[�^���̔����z'
  ||','||'�iVD�j���̔����z'
  ||','||'���z'
FROM  dual
;
select a.sales_base_code       || ',' ||
       a.base_name             || ',' ||
       a.dlv_by_code           || ',' ||
       a.full_name             || ',' ||
       a.delivery_date         || ',' ||
       a.ship_to_customer_code || ',' ||
       a.ACCOUNT_NAME          || ',' ||
       a.dlv_invoice_number    || ',' ||
       a.meaning               || ',' ||
       a.sale_amount_sum       || ',' ||
       a.Cash_And_Card         || ',' ||
       a.cash_total_sales_amt  || ',' ||
       a.card_total_sales_amt  || ',' ||
       a.total_sales_amt       || ',' ||
       a.difference
from  (
------------���������㍷�ك`�F�b�N��
SELECT
   xseh.sales_base_code              as sales_base_code      -- ���㋒�_�R�[�h
  ,xrsv.base_name                    as base_name            -- ���_��
  ,xseh.dlv_by_code                  as dlv_by_code          -- �[�i�҃R�[�h
  ,xev.full_name                     as full_name            -- �[�i�Җ�
  ,xseh.delivery_date                as delivery_date        -- �[�i��
--  ,xseh.hht_dlv_input_date              "HHT�[�i���͓���
--  ,xseh.order_no_hht                    "��No(HHT)
--  ,xseh.digestion_ln_number             "��No(HHT)�}��
  ,xseh.ship_to_customer_code        as ship_to_customer_code-- �ڋq�R�[�h
  ,xca.ACCOUNT_NAME                  as ACCOUNT_NAME         -- �ڋq��
  ,xseh.dlv_invoice_number           as dlv_invoice_number   -- �[�i�`�[�ԍ�
  ,xcsc_v.meaning                    as meaning              -- �J�[�h���敪
  ,xseh.sale_amount_sum              as sale_amount_sum      --�i�`�[�j������z
  ,sum(xsel.Cash_And_Card)           as Cash_And_Card        --�i�`�[�j�����J�[�h���p�z
  ,xseh.cash_total_sales_amt         as cash_total_sales_amt -- �iVD�j��������g�[�^���̔����z
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt as card_total_sales_amt  -- �iVD�j�J�[�h�g�[�^���̔����z
  ,xseh.total_sales_amt              as total_sales_amt      -- ���̔����z
  ,xseh.cash_total_sales_amt - xseh.sale_amount_sum  as difference -- ���z
FROM
   xxcos.xxcos_sales_exp_headers   xseh
  ,XXCOS.Xxcos_Sales_Exp_Lines     xsel
  ,apps.xxcso_employees_v3         xev
  ,apps.XXCSO_RESOURCES_SECURITY_V xrsv
  ,apps.xxcso_cust_accounts_v      xca
  ,(SELECT  lookup_code
           ,meaning
    FROM    applsys.fnd_lookup_values
    WHERE   language     = 'JA'
    AND     enabled_flag = 'Y'
    AND     lookup_type  = 'XXCOS1_CARD_SALE_CLASS'
    ) xcsc_v                                      -- �J�[�h���敪
WHERE xseh.sales_base_code     = xrsv.base_code
and   Xseh.Sales_Exp_Header_Id = Xsel.Sales_Exp_Header_Id
and   xseh.dlv_by_code         = xev.employee_number
and   xseh.ship_to_customer_code = xca.ACCOUNT_NUMBER
AND   xseh.card_sale_class     = xcsc_v.lookup_code(+)   -- �J�[�h���敪
/* �o�C���h�ϐ��̓R�����g�A�E�g�^�p�ł��肢���܂��B�����Ȃ��ł��������I�ǉ���OK�ł� */
--AND xseh.dlv_invoice_number = :invoice                 -- �[�i�`�[�ԍ�
--AND xseh.ship_to_customer_code = :cust                 -- �ڋq�R�[�h
--AND xseh.sales_base_code = :sbase                      -- ���㋒�_
AND xseh.delivery_date >= trunc(sysdate-30)                 -- �[�i��
--AND xseh.delivery_date BETWEEN  TO_DATE(:sddate) AND TO_DATE(:eddate)  -- �[�i��From-To
and xseh.card_sale_class = '0'                --�J�[�h���敪�F����
and xseh.hht_received_flag  = 'Y'             --HHT��M�t���O
and xseh.sale_amount_sum <> xseh.cash_total_sales_amt   -- ������z���v����������g�[�^���̔����z
GROUP BY xseh.sales_base_code, xrsv.base_name, xseh.dlv_by_code, xev.full_name, xseh.delivery_date, xseh.ship_to_customer_code, xca.ACCOUNT_NAME, xseh.dlv_invoice_number, xcsc_v.meaning, xseh.sale_amount_sum, xseh.cash_total_sales_amt, xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt, xseh.total_sales_amt, xseh.cash_total_sales_amt - xseh.sale_amount_sum
union all
------------���J�[�h���㍷�ك`�F�b�N��
SELECT
   xseh.sales_base_code              as sales_base_code      -- ���㋒�_�R�[�h
  ,xrsv.base_name                    as base_name            -- ���_��
  ,xseh.dlv_by_code                  as dlv_by_code          -- �[�i�҃R�[�h
  ,xev.full_name                     as full_name            -- �[�i�Җ�
  ,xseh.delivery_date                as delivery_date        -- �[�i��
--  ,xseh.hht_dlv_input_date              "HHT�[�i���͓���"
--  ,xseh.order_no_hht                    "��No(HHT)"
--  ,xseh.digestion_ln_number             "��No(HHT)�}��"
  ,xseh.ship_to_customer_code        as ship_to_customer_code-- �ڋq�R�[�h
  ,xca.ACCOUNT_NAME                  as ACCOUNT_NAME         -- �ڋq��
  ,xseh.dlv_invoice_number           as dlv_invoice_number   -- �[�i�`�[�ԍ�
  ,xcsc_v.meaning                    as meaning              -- �J�[�h���敪
  ,xseh.sale_amount_sum              as sale_amount_sum      --�i�`�[�j������z
  ,sum(xsel.Cash_And_Card)           as Cash_And_Card        --�i�`�[�j�����J�[�h���p�z
  ,xseh.cash_total_sales_amt         as cash_total_sales_amt -- �iVD�j��������g�[�^���̔����z
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt as card_total_sales_amt  -- �iVD�j�J�[�h�g�[�^���̔����z
  ,xseh.total_sales_amt              as total_sales_amt      -- ���̔����z
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt - xseh.sale_amount_sum  as difference -- ���z
FROM
   xxcos.xxcos_sales_exp_headers   xseh
  ,XXCOS.Xxcos_Sales_Exp_Lines     xsel
  ,apps.xxcso_employees_v3         xev
  ,apps.XXCSO_RESOURCES_SECURITY_V xrsv
  ,apps.xxcso_cust_accounts_v      xca
  ,(SELECT  lookup_code
           ,meaning
    FROM    applsys.fnd_lookup_values
    WHERE   language     = 'JA'
    AND     enabled_flag = 'Y'
    AND     lookup_type  = 'XXCOS1_CARD_SALE_CLASS'
   ) xcsc_v                                      -- �J�[�h���敪
WHERE xseh.sales_base_code     = xrsv.base_code
and   Xseh.Sales_Exp_Header_Id = Xsel.Sales_Exp_Header_Id
and   xseh.dlv_by_code         = xev.employee_number
and   xseh.ship_to_customer_code = xca.ACCOUNT_NUMBER
AND   xseh.card_sale_class     = xcsc_v.lookup_code(+)   -- �J�[�h���敪
/* �o�C���h�ϐ��̓R�����g�A�E�g�^�p�ł��肢���܂��B�����Ȃ��ł��������I�ǉ���OK�ł� */
--AND   xseh.dlv_invoice_number = :invoice                  -- �[�i�`�[�ԍ�
--AND xseh.ship_to_customer_code = :cust                      -- �ڋq�R�[�h
--AND xseh.sales_base_code = :sbase                         -- ���㋒�_
AND xseh.delivery_date >= trunc(sysdate-30)                  -- �[�i��
--AND xseh.delivery_date BETWEEN  TO_DATE(:sddate) AND TO_DATE(:eddate)  -- �[�i��From-To
and xseh.card_sale_class = '1'                --�J�[�h���敪�F�J�[�h
and xseh.hht_received_flag  = 'Y'             --HHT��M�t���O
and xseh.sale_amount_sum <> (xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt)   -- ������z���v���J�[�h���g�[�^���̔����z
group by    xseh.sales_base_code
  ,xrsv.base_name
  ,xseh.dlv_by_code
  ,xev.full_name
  ,xseh.delivery_date
  ,xseh.ship_to_customer_code
  ,xca.ACCOUNT_NAME
  ,xseh.dlv_invoice_number
  ,xcsc_v.meaning
  ,xseh.sale_amount_sum
  ,xseh.cash_total_sales_amt
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt
  ,xseh.total_sales_amt
order by 1,3,5,6,7,8 desc) a
;
exit;

