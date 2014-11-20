CREATE OR REPLACE PACKAGE BODY apps.xxcos_edi_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_edi_common_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_COS_���ʊ֐�
 * Version                : 1.9
 *
 * Program List
 *  ----------------------------- ---- ----- -----------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------- ---- ----- -----------------------------------------
 *  edi_manual_order_acquisition  P          EDI�󒍎���͕��捞
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/26   1.0   H.Fujimoto       �V�K�쐬
 *  2009/03/03   1.1   H.Fujimoto       �����s�No152
 *  2009/03/24   1.2   T.Miyata         ST��Q�FT1_0126
 *  2009/04/24   1.3   K.Kiriu          ST��Q�FT1_0112
 *  2009/06/19   1.4   N.Maeda          [T1_1358]�Ή�
 *  2009/07/13   1.5   K.Kiriu          [0000660]�Ή�
 *  2009/07/14   1.6   K.Kiriu          [0000064]�Ή�
 *  2009/08/11   1.7   K.Kiriu          [0000966]�Ή�
 *  2010/03/09   1.8   S.Karikomi       [E_�{�ғ�_01637]�Ή�
 *  2010/04/15   1.9   S.Karikomi       [E_�{�ғ�_02296]�Ή�
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
--
  /**********************************************************************************
   * Procedure Name   : edi_manual_order_acquisition
   * Description      : EDI�󒍎���͕��捞
   ***********************************************************************************/
  PROCEDURE edi_manual_order_acquisition(
               iv_edi_chain_code           IN VARCHAR2  DEFAULT NULL  -- EDI�`�F�[���X�R�[�h
              ,iv_edi_forward_number       IN VARCHAR2  DEFAULT NULL  -- EDI�`���ǔ�
              ,id_shop_delivery_date_from  IN DATE      DEFAULT NULL  -- �X�ܔ[�i��(From)
              ,id_shop_delivery_date_to    IN DATE      DEFAULT NULL  -- �X�ܔ[�i��(To)
              ,iv_regular_ar_sale_class    IN VARCHAR2  DEFAULT NULL  -- ��ԓ����敪
              ,iv_area_code                IN VARCHAR2  DEFAULT NULL  -- �n��R�[�h
              ,id_center_delivery_date     IN DATE      DEFAULT NULL  -- �Z���^�[�[�i��
              ,in_organization_id          IN NUMBER    DEFAULT NULL  -- �݌ɑg�DID
              ,ov_errbuf                   OUT NOCOPY VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode                  OUT NOCOPY VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg                   OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_edi_common_pkg.edi_manual_order_acquisition'; -- �v���O������
--
/* 2009/07/13 Ver1.5 Add Start */
    --���b�Z�[�W
    cv_msg_sales_class      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00034';  --����敪���݃G���[
    cv_msg_not_outbound     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13593';  --OUTBOUD�ۃG���[
/* 2009/08/11 Ver1.7 Add Start */
    cv_msg_prf_err          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';  --�v���t�@�C���擾�G���[
    cv_msg_org_prf_name     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';  --MO:�c�ƒP��
/* 2009/08/11 Ver1.7 Add End   */
    --�g�[�N��
    cv_tkn_order_no         CONSTANT VARCHAR2(20) := 'ORDER_NO';          --�`�[�ԍ�
    cv_tkn_line_no          CONSTANT VARCHAR2(20) := 'LINE_NUMBER';       --���הԍ�
/* 2009/07/13 Ver1.5 Add End   */
/* 2009/08/11 Ver1.7 Add Start */
    cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';           --�v���t�@�C��
/* 2009/08/11 Ver1.7 Add End   */
    cv_cstm_class_base      CONSTANT VARCHAR2(2)  := '1';       -- �ڋq�敪:���_
/* 2010/04/15 Ver1.9 Add Start */
    cv_hw_slip_div_yes      CONSTANT VARCHAR2(1)  := '1';       -- EDI�菑�`�[�`���敪:�`������
/* 2010/04/15 Ver1.9 Add End   */
    cv_cstm_class_customer  CONSTANT VARCHAR2(2)  := '10';      -- �ڋq�敪:�ڋq
    cv_cstm_class_chain     CONSTANT VARCHAR2(2)  := '18';      -- �ڋq�敪:�`�F�[���X
    cv_flow_status_entry    CONSTANT VARCHAR2(6)  := 'BOOKED';  -- �X�e�[�^�X:�L���ς�
--*** 2009/03/24 Ver1.3 MODIFY START ***
--  cn_order_source         CONSTANT NUMBER       := 0;         -- �󒍃\�[�XID:��ʓ���
--  cn_order_type           CONSTANT NUMBER       := 1068;      -- �󒍃^�C�vID:�ʏ��
--  cn_line_type            CONSTANT NUMBER       := 1054;      -- ���׃^�C�vID:�ʏ�o��
    cv_xxcos_appl_short_nm  CONSTANT VARCHAR2(5)  := 'XXCOS';   -- �̕��Z�k�A�v����
    cv_xxcos1_order_edi_common                                  -- EDI����͓���}�X�^
                            CONSTANT VARCHAR2(23) := 'XXCOS1_ORDER_EDI_COMMON';
--*** 2009/03/24 Ver1.3 MODIFY END   ***
    cv_tukzik_div_tuk       CONSTANT VARCHAR2(2)  := '11';      -- �ʉߍ݌Ɍ^�敪:�Z���^�[�[�i(�ʉߌ^�E��)
    cv_tukzik_div_zik       CONSTANT VARCHAR2(2)  := '12';      -- �ʉߍ݌Ɍ^�敪:�Z���^�[�[�i(�݌Ɍ^�E��)
    cv_tukzik_div_tnp       CONSTANT VARCHAR2(2)  := '24';      -- �ʉߍ݌Ɍ^�敪:�X�ܔ[�i
    cv_flag_yes             CONSTANT VARCHAR2(1)  := 'Y';       -- �t���O:'Y'
    cv_flag_no              CONSTANT VARCHAR2(1)  := 'N';       -- �t���O:'N'
--************************** 2009/06/19 N.Maeda Mod start *********************************--
--    cv_ras_class_all        CONSTANT VARCHAR2(1)  := '0';       -- ��ԓ����敪:ALL
    cv_ras_class_all        CONSTANT VARCHAR2(2)  := '00';      -- ��ԓ����敪:ALL
--************************** 2009/06/19 N.Maeda Mod  end  *********************************--
    cv_unit_case            CONSTANT VARCHAR2(2)  := 'CS';      -- �P��:�P�[�X
    cv_unit_bowl            CONSTANT VARCHAR2(2)  := 'BL';      -- �P��:�{�[��
/* 2009/07/13 Ver1.5 Del Start */
--    cv_sale_class_error     CONSTANT VARCHAR2(1)  := '1';       -- ����敪���݃G���[
--    cv_outbound_error       CONSTANT VARCHAR2(1)  := '2';       -- OUTBOUND�ۃG���[
/* 2009/07/13 Ver1.5 Del End   */
    cv_medium_class         CONSTANT VARCHAR2(2)  := '01';      -- �}�̋敪
    cv_data_type_code       CONSTANT VARCHAR2(2)  := '11';      -- �f�[�^��R�[�h
    cv_creation_class       CONSTANT VARCHAR2(2)  := '01';      -- �쐬���敪
    cv_file_no              CONSTANT VARCHAR2(2)  := '00';      -- �t�@�C���m��
    cv_stockout_class       CONSTANT VARCHAR2(2)  := '00';      -- ���i�敪
    cv_user_env_lang        CONSTANT VARCHAR2(4)  := 'lang';    -- ���ϐ�:����
    cv_ltype_sale_class     CONSTANT VARCHAR2(25) := 'XXCOS1_SALE_CLASS';  -- �Q�ƃ^�C�v�E�R�[�h:����敪
    cv_tbl_name_head        CONSTANT VARCHAR2(13) := 'EDI�w�b�_���';      -- �e�[�u����:EDI�w�b�_���
    cv_tbl_name_line        CONSTANT VARCHAR2(11) := 'EDI���׏��';        -- �e�[�u����:EDI���׏��
/* 2009/08/11 Ver1.7 Add Start */
    --�v���t�@�C������
    ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID'; --MO:�c�ƒP��
/* 2009/08/11 Ver1.7 Add Start */
--
    -- �w�b�_�e�[�u��
    TYPE order_head_rtype IS RECORD (
         acquisition_flag       xxcos_edi_headers.order_connection_number%TYPE   -- EDI�w�b�_���.�󒍊֘A�ԍ�
        ,header_id              oe_order_headers_all.header_id%TYPE              -- �󒍃w�b�_.�󒍃w�b�_ID
        ,ordered_date           oe_order_headers_all.ordered_date%TYPE           -- �󒍃w�b�_.�󒍓�
        ,request_date           oe_order_headers_all.request_date%TYPE           -- �󒍃w�b�_.�v����
        ,cust_po_number         oe_order_headers_all.cust_po_number%TYPE         -- �󒍃w�b�_.�ڋq����
        ,order_number           oe_order_headers_all.order_number%TYPE           -- �󒍃w�b�_.�󒍔ԍ�
        ,orig_sys_document_ref  oe_order_headers_all.orig_sys_document_ref%TYPE  -- �󒍃w�b�_.�O���V�X�e���󒍔ԍ�
        ,price_list_id          oe_order_headers_all.price_list_id%TYPE          -- �󒍃w�b�_.���i�\ID
/* 2009/07/14 Ver1.6 Add Start */
        ,invoice_class          oe_order_headers_all.attribute5%TYPE             -- �󒍃w�b�_.DFF5(�`�[�敪)
        ,classification_code    oe_order_headers_all.attribute20%TYPE            -- �󒍃w�b�_.DFF20(���ދ敪)
/* 2009/07/14 Ver1.6 Add End   */
        ,account_number         hz_cust_accounts.account_number%TYPE             -- �ڋq�}�X�^(�ڋq).�ڋq�R�[�h
        ,customer_name          hz_parties.party_name%TYPE                       -- �p�[�e�B(�ڋq).����
        ,customer_name_alt      hz_parties.organization_name_phonetic%TYPE       -- �p�[�e�B(�ڋq).����(�J�i)
        ,base_code              xxcmm_cust_accounts.delivery_base_code%TYPE      -- �ڋq�ǉ�(�ڋq).�[�i���_�R�[�h
        ,store_code             xxcmm_cust_accounts.store_code%TYPE              -- �ڋq�ǉ�(�ڋq).�X�܃R�[�h
        ,cust_store_name        xxcmm_cust_accounts.cust_store_name%TYPE         -- �ڋq�ǉ�(�ڋq).�ڋq�X�ܖ���
        ,edi_district_code      xxcmm_cust_accounts.edi_district_code%TYPE       -- �ڋq�ǉ�(�ڋq).EDI�n��R�[�h(EDI)
        ,edi_district_name      xxcmm_cust_accounts.edi_district_name%TYPE       -- �ڋq�ǉ�(�ڋq).EDI�n�於(EDI)
        ,edi_district_kana      xxcmm_cust_accounts.edi_district_kana%TYPE       -- �ڋq�ǉ�(�ڋq).EDI�n�於�J�i(EDI)
        ,edi_chain_code         xxcmm_cust_accounts.edi_chain_code%TYPE          -- �ڋq�ǉ�(����).EDI�`�F�[���X�R�[�h
        ,edi_chain_name         hz_parties.party_name%TYPE                       -- �p�[�e�B(����).����
        ,edi_chain_name_alt     hz_parties.organization_name_phonetic%TYPE       -- �p�[�e�B(����).����(�J�i)
        ,base_name              hz_parties.party_name%TYPE                       -- �p�[�e�B(���_).����
        ,base_name_alt          hz_parties.organization_name_phonetic%TYPE       -- �p�[�e�B(���_).����(�J�i)
    );
    -- ���׃e�[�u��
    TYPE order_line_rtype IS RECORD (
         line_number         oe_order_lines_all.line_number%TYPE         -- �󒍖���.�s�ԍ�
        ,ordered_item        oe_order_lines_all.ordered_item%TYPE        -- �󒍖���.�󒍕i��
        ,order_quantity_uom  oe_order_lines_all.order_quantity_uom%TYPE  -- �󒍖���.�󒍒P��
        ,ordered_quantity    oe_order_lines_all.ordered_quantity%TYPE    -- �󒍖���.�󒍐���
        ,orig_sys_line_refw  oe_order_lines_all.orig_sys_line_ref%TYPE   -- �󒍖���.�O���V�X�e���󒍖��הԍ�
        ,unit_selling_price  oe_order_lines_all.unit_selling_price%TYPE  -- �̔��P��
/* 2010/03/09 Ver1.8 Add Start */
        ,selling_price       xxcos_edi_lines.selling_price%TYPE          -- ���P��
        ,order_price_amt     xxcos_edi_lines.order_price_amt%TYPE        -- �������z(����)
/* 2010/03/09 Ver1.8 Add  End  */
        ,num_of_case         ic_item_mst_b.attribute11%TYPE              -- OPM�i��.DFF11(�P�[�X����)
        ,jan_code            ic_item_mst_b.attribute21%TYPE              -- OPM�i��.DFF21(JAN�R�[�h)
        ,itf_code            ic_item_mst_b.attribute22%TYPE              -- OPM�i��.DFF22(ITF�R�[�h)
        ,item_code           mtl_system_items_b.segment1%TYPE            -- Disc�i��.�i���R�[�h
        ,num_of_bowl         xxcmm_system_items_b.bowl_inc_num%TYPE      -- Disc�i�ڃA�h�I��.�{�[������
        ,regular_sale_class  fnd_lookup_values.attribute8%TYPE           -- �N�C�b�N�R�[�h.DFF8(��ԓ����敪)
        ,outbound_flag       fnd_lookup_values.attribute10%TYPE          -- �N�C�b�N�R�[�h.DFF10(OUTBOUND��)
/* 2009/03/03 Ver1.1 Add Start */
        ,item_name           xxcmn_item_mst_b.item_name%TYPE             -- OPM�i�ڃA�h�I��.������
        ,item_name_alt       xxcmn_item_mst_b.item_name_alt%TYPE         -- OPM�i�ڃA�h�I��.�J�i��
/* 2009/03/03 Ver1.1 Add  End  */
/* 2009/04/24 Ver1.3 Add Start */
        ,edi_rep_uom         mtl_units_of_measure_tl.attribute1%TYPE     -- EDI�E���[�p�P��
/* 2009/04/24 Ver1.3 Add End   */
    );
    -- �`�[�v�e�[�u��
    TYPE invoice_sum_rtype IS RECORD (
         invoice_number               VARCHAR2(50)      -- �`�[�ԍ�
        ,invoice_indv_order_qty       NUMBER DEFAULT 0  -- ��������(�o��)
        ,invoice_case_order_qty       NUMBER DEFAULT 0  -- ��������(�P�[�X)
        ,invoice_ball_order_qty       NUMBER DEFAULT 0  -- ��������(�{�[��)
        ,invoice_sum_order_qty        NUMBER DEFAULT 0  -- ��������(���v�A�o��)
        ,invoice_indv_shipping_qty    NUMBER DEFAULT 0  -- �o�א���(�o��)
        ,invoice_case_shipping_qty    NUMBER DEFAULT 0  -- �o�א���(�P�[�X)
        ,invoice_ball_shipping_qty    NUMBER DEFAULT 0  -- �o�א���(�{�[��)
        ,invoice_pallet_shipping_qty  NUMBER DEFAULT 0  -- �o�א���(�p���b�g)
        ,invoice_sum_shipping_qty     NUMBER DEFAULT 0  -- �o�א���(���v�A�o��)
        ,invoice_indv_stockout_qty    NUMBER DEFAULT 0  -- ���i����(�o��)
        ,invoice_case_stockout_qty    NUMBER DEFAULT 0  -- ���i����(�P�[�X)
        ,invoice_ball_stockout_qty    NUMBER DEFAULT 0  -- ���i����(�{�[��)
        ,invoice_sum_stockout_qty     NUMBER DEFAULT 0  -- ���i����(���v�A�o��)
        ,invoice_case_qty             NUMBER DEFAULT 0  -- �P�[�X����
        ,invoice_fold_container_qty   NUMBER DEFAULT 0  -- �I���R��(�o��)����
        ,invoice_order_cost_amt       NUMBER DEFAULT 0  -- �������z(����)
        ,invoice_shipping_cost_amt    NUMBER DEFAULT 0  -- �������z(�o��)
        ,invoice_stockout_cost_amt    NUMBER DEFAULT 0  -- �������z(���i)
        ,invoice_order_price_amt      NUMBER DEFAULT 0  -- �������z(����)
        ,invoice_shipping_price_amt   NUMBER DEFAULT 0  -- �������z(�o��)
        ,invoice_stockout_price_amt   NUMBER DEFAULT 0  -- �������z(���i)
    );
    -- �w�b�_�ҏW�e�[�u��
    TYPE head_edit_rtype IS RECORD (
         edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE  -- EDI�w�b�_���ID
        ,ar_sale_class       xxcos_edi_headers.ar_sale_class%TYPE       -- �����敪
    );
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    -- PL/SQL�\�^
    TYPE order_head_ttype   IS TABLE OF order_head_rtype   INDEX BY BINARY_INTEGER;  -- �w�b�_�e�[�u��
    TYPE order_line_ttype   IS TABLE OF order_line_rtype   INDEX BY BINARY_INTEGER;  -- ���׃e�[�u��
    TYPE invoice_sum_ttype  IS TABLE OF invoice_sum_rtype  INDEX BY BINARY_INTEGER;  -- �`�[�v�e�[�u��
    TYPE head_edit_ttype    IS TABLE OF head_edit_rtype    INDEX BY BINARY_INTEGER;  -- �w�b�_�ҏW�e�[�u��
--
    -- PL/SQL�\
    lt_head_tab          order_head_ttype;     -- �w�b�_�e�[�u��
    lt_line_tab          order_line_ttype;     -- ���׃e�[�u��
    lt_invoice_tab       invoice_sum_ttype;    -- �`�[�v�e�[�u��
    lt_head_edit_tab     head_edit_ttype;      -- �w�b�_�ҏW�e�[�u��
--
    ln_head_cnt          NUMBER;           -- �w�b�_�e�[�u���p�J�E���^
    ln_line_cnt          NUMBER;           -- ���׃e�[�u���p�J�E���^
    ln_invoice_cnt       NUMBER;           -- �`�[�v�e�[�u���p�J�E���^
    lv_sale_class_check  VARCHAR2(1);      -- ����敪�Ώ�
    ln_line_info_id      NUMBER;           -- EDI���׏��ID
    ln_user_id           NUMBER;           -- ���[�UID
    ln_login_id          NUMBER;           -- ���O�C��ID
    ld_sysdate           DATE;             -- �V�X�e�����t
    ln_case_qty          NUMBER;           -- �P�[�X��
    ln_bowl_qty          NUMBER;           -- �{�[����
    ln_indv_qty          NUMBER;           -- �o����
    lv_language          VARCHAR2(10);     -- ����
--
    lv_product_code2     VARCHAR2(16);     -- ���i�R�[�h�Q
    lv_jan_code          VARCHAR2(13);     -- JAN�R�[�h
    lv_case_jan_code     VARCHAR2(13);     -- �P�[�XJAN�R�[�h
    lv_table_name        VARCHAR2(15);     -- �e�[�u����
    lv_errbuf            VARCHAR2(5000);   -- �G���[�E���b�Z�[�W�G���[
    lv_retcode           VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_ret_normal        VARCHAR2(1);      -- ���^�[���E�R�[�h:����
/* 2009/08/11 Ver1.7 Add Start */
    ln_org_id            NUMBER;           -- ORG_ID
    lv_msg_string        VARCHAR2(5000);   -- ���b�Z�[�W�p������i�[�ϐ�
    ld_shop_delivery_date_from DATE;       -- ����TRUNC�p(�X�ܔ[�i��Form)
    ld_shop_delivery_date_to   DATE;       -- ����TRUNC�p(�X�ܔ[�i��To)
    ld_center_delivery_date    DATE;       -- ����TRUNC�p(�Z���^�[�[�i��)
/* 2009/08/11 Ver1.7 Add End   */
--
    -- ================
    -- ���[�U�[��`��O
    -- ================
    sale_class_expt    EXCEPTION;  -- ����敪�����݂����ꍇ�̗�O
    outbound_expt      EXCEPTION;  -- OUTBOUND�ۂ�'N'�̏ꍇ�̗�O
    table_insert_expt  EXCEPTION;  -- �}���Ɏ��s�����ꍇ�̗�O
    item_conv_expt     EXCEPTION;  -- �i�ڕϊ��̗�O
/* 2009/08/11 Ver1.7 Add Start */
    org_id_expt        EXCEPTION;  -- ORG_ID�擾��O
/* 2009/08/11 Ver1.7 Add End   */
--
    PRAGMA EXCEPTION_INIT(sale_class_expt,   -20000);
    PRAGMA EXCEPTION_INIT(outbound_expt,     -20001);
    PRAGMA EXCEPTION_INIT(table_insert_expt, -20002);
    PRAGMA EXCEPTION_INIT(item_conv_expt,    -20003);
/* 2009/08/11 Ver1.7 Add Start */
    PRAGMA EXCEPTION_INIT(org_id_expt,       -20004);
/* 2009/08/11 Ver1.7 Add End   */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_user_id     := FND_GLOBAL.USER_ID;                  -- ���[�UID
    ln_login_id    := FND_GLOBAL.LOGIN_ID;                 -- ���O�C��ID
    ld_sysdate     := TRUNC(SYSDATE);                      -- �V�X�e�����t
    lv_language    := USERENV(cv_user_env_lang);           -- ����
    lv_ret_normal  := xxccp_common_pkg.set_status_normal;  -- ���^�[���R�[�h:����
/* 2009/08/11 Ver1.7 Add Start */
    ld_shop_delivery_date_from  := TRUNC(id_shop_delivery_date_from);  -- ������TRUNC(�X�ܔ[�i��Form)
    ld_shop_delivery_date_to    := TRUNC(id_shop_delivery_date_to);    -- ������TRUNC(�X�ܔ[�i��To)
    ld_center_delivery_date     := TRUNC(id_center_delivery_date);     -- ������TRUNC(�Z���^�[�[�i��)
--
    ln_org_id      := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_org_id ) ); -- ORG_ID
--
    --ORG_ID���擾�ł��Ȃ��ꍇ�̓G���[
    IF ( ln_org_id IS NULL ) THEN
      lv_msg_string := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_nm
                         ,iv_name        => cv_msg_org_prf_name
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_nm
                     ,iv_name         => cv_msg_prf_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => lv_msg_string
                   );
      RAISE org_id_expt;
    END IF;
/* 2009/08/11 Ver1.7 Add End   */
--
    -- �w�b�_���Ǎ�
    SELECT
/* 2009/08/11 Ver1.7 Add Start */
       /*+
          LEADING(xca2)
          USE_NL(xca1)
       */
/* 2009/08/11 Ver1.7 Add End   */
       xeh.order_connection_number     -- EDI�w�b�_���.�󒍊֘A�ԍ�
      ,ooha.header_id                  -- �󒍃w�b�_.�󒍃w�b�_ID
      ,ooha.ordered_date               -- �󒍃w�b�_.�󒍓�
      ,ooha.request_date               -- �󒍃w�b�_.�v����
      ,ooha.cust_po_number             -- �󒍃w�b�_.�ڋq����
      ,ooha.order_number               -- �󒍃w�b�_.�󒍔ԍ�
      ,ooha.orig_sys_document_ref      -- �󒍃w�b�_.�O���V�X�e���󒍔ԍ�
      ,ooha.price_list_id              -- �󒍃w�b�_.���i�\ID
/* 2009/07/14 Ver1.6 Add Start */
      ,ooha.attribute5                 -- �󒍃w�b�_.DFF5(�`�[�敪)
      ,ooha.attribute20                -- �󒍃w�b�_.DFF20(���ދ敪)
/* 2009/07/14 Ver1.6 Add End   */
      ,hca1.account_number             -- �ڋq�}�X�^(�ڋq).�ڋq�R�[�h
      ,hp1.party_name                  -- �p�[�e�B(�ڋq).����
      ,hp1.organization_name_phonetic  -- �p�[�e�B(�ڋq).����(�J�i)
      ,xca1.delivery_base_code         -- �ڋq�ǉ�(�ڋq).�[�i���_�R�[�h
      ,xca1.store_code                 -- �ڋq�ǉ�(�ڋq).�X�܃R�[�h
      ,xca1.cust_store_name            -- �ڋq�ǉ�(�ڋq).�ڋq�X�ܖ���
      ,xca1.edi_district_code          -- �ڋq�ǉ�(�ڋq).EDI�n��R�[�h(EDI)
      ,xca1.edi_district_name          -- �ڋq�ǉ�(�ڋq).EDI�n�於(EDI)
      ,xca1.edi_district_kana          -- �ڋq�ǉ�(�ڋq).EDI�n�於�J�i(EDI)
      ,xca2.edi_chain_code             -- �ڋq�ǉ�(����).EDI�`�F�[���X�R�[�h
      ,hp2.party_name                  -- �p�[�e�B(����).����
      ,hp2.organization_name_phonetic  -- �p�[�e�B(����).����(�J�i)
      ,hp3.party_name                  -- �p�[�e�B(���_).����
      ,hp3.organization_name_phonetic  -- �p�[�e�B(���_).����(�J�i)
     BULK COLLECT INTO lt_head_tab
     FROM oe_order_headers_all  ooha  -- �󒍃w�b�_
         ,hz_cust_accounts      hca1  -- �ڋq�}�X�^(�ڋq)
         ,xxcmm_cust_accounts   xca1  -- �ڋq�ǉ�(�ڋq)
         ,hz_parties            hp1   -- �p�[�e�B(�ڋq)
         ,hz_cust_accounts      hca2  -- �ڋq�}�X�^(����)
         ,xxcmm_cust_accounts   xca2  -- �ڋq�ǉ�(����)
         ,hz_parties            hp2   -- �p�[�e�B(����)
         ,hz_cust_accounts      hca3  -- �ڋq�}�X�^(���_)
         ,hz_parties            hp3   -- �p�[�e�B(���_)
         ,xxcos_edi_headers     xeh   -- EDI�w�b�_���
--*** 2009/03/24 Ver1.3 ADD    START ***
         ,oe_order_sources        oos   -- �󒍃\�[�X�e�[�u��
         ,oe_transaction_types_tl ottt  -- �󒍃^�C�v�e�[�u��
--*** 2009/03/24 Ver1.3 ADD    END   ***/
     WHERE ooha.sold_to_org_id         =  hca1.cust_account_id            -- �󒍃w�b�_      ���ڋq�}�X�^(�ڋq)
/* 2009/08/11 Ver1.7 Mod Start */
--     AND   hca1.cust_account_id        =  xca1.customer_id                -- �ڋq�}�X�^(�ڋq)���ڋq�ǉ�(�ڋq)
     AND   hca1.account_number         =  xca1.customer_code              -- �ڋq�}�X�^(�ڋq)���ڋq�ǉ�(�ڋq)
/* 2009/08/11 Ver1.7 Mod End   */
     AND   hca1.party_id               =  hp1.party_id                    -- �ڋq�}�X�^(�ڋq)���p�[�e�B(�ڋq)
     AND   xca1.chain_store_code       =  xca2.edi_chain_code             -- �ڋq�ǉ�(�ڋq)  ���ڋq�ǉ�(����)
     AND   hca2.cust_account_id        =  xca2.customer_id                -- �ڋq�}�X�^(����)���ڋq�ǉ�(����)
     AND   hca2.party_id               =  hp2.party_id                    -- �ڋq�}�X�^(����)���p�[�e�B(����)
     AND   xca1.delivery_base_code     =  hca3.account_number             -- �ڋq�}�X�^(�ڋq)���ڋq�}�X�^(���_)
     AND   hca3.party_id               =  hp3.party_id                    -- �ڋq�}�X�^(���_)���p�[�e�B(���_)
     AND   ooha.orig_sys_document_ref  =  xeh.order_connection_number(+)  -- �󒍃w�b�_      ��EDI�w�b�_���
     /* �ڋq�敪 */
     AND   hca1.customer_class_code    =  cv_cstm_class_customer   -- �ڋq�}�X�^(�ڋq).�ڋq�敪='10'(�ڋq)
     AND   hca2.customer_class_code    =  cv_cstm_class_chain      -- �ڋq�}�X�^(����).�ڋq�敪='18'(���ݓX)
     AND   hca3.customer_class_code    =  cv_cstm_class_base       -- �ڋq�}�X�^(���_).�ڋq�敪='1'(���_)
/* 2010/04/15 Ver1.9 Add Start */
     /* EDI�菑�`�[�`���敪 */ 
     AND   xca2.handwritten_slip_div   =  cv_hw_slip_div_yes       -- �ڋq�ǉ�(����).EDI�菑�`�[�`���敪��'1'(�`������)
/* 2010/04/15 Ver1.9 Add End   */
     /* �󒍃w�b�_���o���� */
/* 2009/08/11 Ver1.7 Add Start */
     AND   ooha.org_id                 =  ln_org_id              -- ORG_ID���v���t�@�C���l
/* 2009/08/11 Ver1.7 Add End   */
     AND   ooha.flow_status_code       =  cv_flow_status_entry   -- �X�e�[�^�X  ���L���ς�
--*** 2009/03/24 Ver1.3 MODIFY START ***
--   AND   ooha.order_source_id        =  cn_order_source        -- �󒍃\�[�XID����ʓ���
--   AND   ooha.order_type_id          =  cn_order_type          -- �󒍃^�C�vID���ʏ��
--
     AND   ooha.order_source_id        =  oos.order_source_id      -- �󒍃w�b�_.�󒍃\�[�XID���󒍃\�[�X.�󒍃\�[�XID
     AND   ooha.order_type_id          =  ottt.transaction_type_id -- �󒍃w�b�_.�󒍃^�C�vID���󒍃^�C�v.�󒍃^�C�vID
/* 2009/08/11 Ver1.7 Mod Start */
--     AND   ottt.language               =  USERENV('LANG')          -- �󒍃^�C�v.���ꁁ���{��
     AND   ottt.language               =  lv_language            -- �󒍃^�C�v.���ꁁ���{��
/* 2009/08/11 Ver1.7 Mod End   */
     AND   EXISTS (
                   SELECT 'X'
/* 2009/08/11 Ver1.7 Mod Start */
--                   FROM (
--                          SELECT
--                            flv.attribute1 AS order_source_name  -- �󒍃\�[�X
--                           ,flv.attribute2 AS order_h_type_name  -- �󒍃w�b�_�^�C�v
--                          FROM
--                             fnd_application               fa,
--                             fnd_lookup_types              flt,
--                             fnd_lookup_values             flv
--                           WHERE
--                               fa.application_id           = flt.application_id
--                           AND flt.lookup_type             = flv.lookup_type
--                           AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                           AND flv.lookup_type             = cv_xxcos1_order_edi_common
--                           AND flv.start_date_active      <= TRUNC( ld_sysdate )
--                           AND TRUNC( ld_sysdate )        <= NVL( flv.end_date_active, TRUNC( ld_sysdate ) )
--                           AND flv.enabled_flag            = cv_flag_yes
--                           AND flv.language                = USERENV( 'LANG' )
--                        ) flvs
--                      WHERE
--                          oos.name       = flvs.order_source_name  -- �󒍃\�[�X�D���O���Q�ƃ^�C�v�D�󒍃\�[�X��
--                      AND ottt.name      = flvs.order_h_type_name  -- �󒍃^�C�v�D���O���Q�ƃ^�C�v�D�󒍃w�b�_�^�C�v��
                   FROM   fnd_lookup_values  flv
                   WHERE  flv.lookup_type   = cv_xxcos1_order_edi_common
                   AND    ld_sysdate        BETWEEN NVL( flv.start_date_active, ld_sysdate )
                                            AND     NVL( flv.end_date_active, ld_sysdate )
                   AND    flv.enabled_flag  = cv_flag_yes
                   AND    flv.language      = lv_language
                   AND    flv.attribute1    = oos.name
                   AND    flv.attribute2    = ottt.name
/* 2009/08/11 Ver1.7 Mod End   */
                  )
--*** 2009/03/24 Ver1.3 MODIFY END   ***/
     /* �ʉߌ^�݌ɋ敪 */
     AND   xca1.tsukagatazaiko_div     IN ( cv_tukzik_div_tuk    -- �Z���^�[�[�i(�ʉߌ^�E��)
                                          , cv_tukzik_div_zik    -- �Z���^�[�[�i(�݌Ɍ^�E��)
                                          , cv_tukzik_div_tnp )  -- �X�ܔ[�i
     /* �p�����[�^�ɂ��i�荞�� */
/* 2009/08/11 Ver1.7 Mod Start */
--     AND ( xca2.chain_store_code       =  iv_edi_chain_code                  -- EDI�`�F�[���X�R�[�h
--     OR    iv_edi_chain_code           IS NULL )
     AND   xca2.edi_chain_code         =  iv_edi_chain_code                  -- EDI�`�F�[���X�R�[�h
/* 2009/08/11 Ver1.7 Mod End   */
     AND ( xca1.edi_forward_number     =  iv_edi_forward_number              -- EDI�`���ǔ�
     OR    iv_edi_forward_number       IS NULL )
/* 2009/08/11 Ver1.7 Mod Start */
--     AND ( TRUNC(ooha.request_date)    >= TRUNC(id_shop_delivery_date_from)  -- �X�ܔ[�i��(From)
--     OR    id_shop_delivery_date_from  IS NULL )
--     AND ( TRUNC(ooha.request_date)    <= TRUNC(id_shop_delivery_date_to)    -- �X�ܔ[�i��(To)
--     OR    id_shop_delivery_date_to    IS NULL )
--     AND ( xca1.edi_district_code      =  iv_area_code                       -- �n��R�[�h
--     OR    iv_area_code                IS NULL )
--     AND ( TRUNC(ooha.request_date)    =  TRUNC(id_center_delivery_date)     -- �Z���^�[�[�i��
--     OR    id_center_delivery_date     IS NULL )
     AND (
           TRUNC(ooha.request_date)    >= ld_shop_delivery_date_from  -- �X�ܔ[�i��(From)
         OR
           ld_shop_delivery_date_from  IS NULL
         )
     AND (
           TRUNC(ooha.request_date)    <= ld_shop_delivery_date_to    -- �X�ܔ[�i��(To)
         OR
           ld_shop_delivery_date_to    IS NULL
         )
     AND (
           xca1.edi_district_code      =  iv_area_code                -- �n��R�[�h
         OR
           iv_area_code                IS NULL
         )
     AND (
           TRUNC(ooha.request_date)    =  ld_center_delivery_date     -- �Z���^�[�[�i��
         OR
           ld_center_delivery_date     IS NULL
         )
/* 2009/08/11 Ver1.7 Mod End   */
    ;
--
    -- �Y���f�[�^�Ȃ�
    IF ( lt_head_tab.COUNT = 0 ) THEN
      RETURN;
    END IF;
--
    -- �`�[�v
    ln_invoice_cnt := 1;
    lt_invoice_tab(ln_invoice_cnt).invoice_number := lt_head_tab(1).cust_po_number;
--
    <<head_proc_loop>>
    FOR ln_head_cnt IN 1 .. lt_head_tab.COUNT LOOP
      -- �w�b�_�ҏW�e�[�u��������
      lt_head_edit_tab(ln_head_cnt).edi_header_info_id := NULL;
--
      -- ��荞�ݍς݁H
      IF ( lt_head_tab(ln_head_cnt).acquisition_flag IS NULL ) THEN
        lt_line_tab.DELETE;  -- ���׃e�[�u���N���A
--
        -- ���׏��Ǎ�
        SELECT
          oola.line_number            line_number         -- �󒍖���.�s�ԍ�
         ,oola.ordered_item           ordered_item        -- �󒍖���.�󒍕i��
         ,oola.order_quantity_uom     order_quantity_uom  -- �󒍖���.�󒍒P��
         ,oola.ordered_quantity       ordered_quantity    -- �󒍖���.�󒍐���
         ,oola.orig_sys_line_ref      orig_sys_line_refw  -- �󒍖���.�O���V�X�e���󒍖��הԍ�
         ,oola.unit_selling_price     unit_selling_price  -- �̔��P��
/* 2010/03/09 Ver1.8 Add Start */
         ,TO_NUMBER(oola.attribute10) selling_price       -- ���P��
         ,TO_NUMBER(oola.attribute10)
          * oola.ordered_quantity     order_price_amt     -- �������z(����)
/* 2010/03/09 Ver1.8 Add  End  */
         ,iimb.attribute11            num_of_case         -- OPM�i��.DFF11(�P�[�X����)
         ,iimb.attribute21            jan_code            -- OPM�i��.DFF21(JAN�R�[�h)
         ,iimb.attribute22            itf_code            -- OPM�i��.DFF22(ITF�R�[�h)
         ,msib.segment1               item_code           -- Disc�i��.�i���R�[�h
         ,xsib.bowl_inc_num           num_of_bowl         -- Disc�i�ڃA�h�I��.�{�[������
         ,flv.attribute8              regular_sale_class  -- �N�C�b�N�R�[�h.DFF8(��ԓ����敪)
         ,flv.attribute10             outbound_flag       -- �N�C�b�N�R�[�h.DFF10(OUTBOUND��)
/* 2009/03/03 Ver1.1 Add Start */
         ,ximb.item_name              item_name           -- OPM�i�ڃA�h�I��.������
         ,ximb.item_name_alt          item_name_alt       -- OPM�i�ڃA�h�I��.�J�i��
/* 2009/03/03 Ver1.1 Add  End  */
/* 2009/04/24 Ver1.3 Add Start */
         ,muom.attribute1             edi_rep_uom         -- EDI�E���[�p�P��
/* 2009/04/24 Ver1.3 Add End   */
        BULK COLLECT INTO lt_line_tab
        FROM oe_order_lines_all    oola  -- �󒍖���
            ,ic_item_mst_b         iimb  -- OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b      ximb  -- OPM�i�ڃA�h�I��
            ,mtl_system_items_b    msib  -- Disc�i��
            ,xxcmm_system_items_b  xsib  -- Disc�i�ڃA�h�I��
            ,fnd_lookup_values     flv   -- �N�C�b�N�R�[�h
--*** 2009/03/24 Ver1.3 ADD    START ***/
            ,oe_transaction_types_tl ottt  -- �󒍃^�C�v�e�[�u��
--*** 2009/03/24 Ver1.3 ADD    END   ***/
/* 2009/04/24 Ver1.3 Add Start */
            ,mtl_units_of_measure_tl muom  -- �P�ʃ}�X�^
/* 2009/04/24 Ver1.3 Add End   */
        WHERE oola.header_id            = lt_head_tab(ln_head_cnt).header_id
        AND   oola.ordered_item         = iimb.item_no
        AND   iimb.item_id              = ximb.item_id
        AND   ximb.start_date_active   <= ld_sysdate
        AND   ximb.end_date_active     >= ld_sysdate
        AND   oola.ordered_item         = msib.segment1
        AND   msib.organization_id      = in_organization_id
        AND   msib.segment1             = xsib.item_code
        AND   oola.attribute5           = flv.lookup_code(+)
        AND   flv.lookup_type(+)        = cv_ltype_sale_class
        AND   flv.start_date_active(+) <= ld_sysdate
        AND ( flv.end_date_active      >= ld_sysdate
        OR    flv.end_date_active      IS NULL )
        AND   flv.enabled_flag(+)       = cv_flag_yes
        AND   flv.language(+)           = lv_language
--*** 2009/03/24 Ver1.3 MODIFY START ***
--      AND   oola.line_type_ID         = cn_line_type
        AND   oola.line_type_id         = ottt.transaction_type_id -- �󒍃w�b�_.�󒍃^�C�vID���󒍃^�C�v.�󒍃^�C�vID
/* 2009/08/11 Ver1.7 Mod Start */
--        AND   ottt.language             = USERENV('LANG')          -- �󒍃^�C�v.���ꁁ���{��
        AND   ottt.language             = lv_language              -- �󒍃^�C�v.���ꁁ���{��
/* 2009/08/11 Ver1.7 Mod End   */
        AND   EXISTS (
                      SELECT 'X'
/* 2009/08/11 Ver1.7 Mod Start */
--                      FROM (
--                             SELECT
--                               flv.attribute3 AS order_l_type_name -- �󒍖��׃^�C�v
--                             FROM
--                                fnd_application               fa,
--                                fnd_lookup_types              flt,
--                                fnd_lookup_values             flv
--                              WHERE
--                                  fa.application_id           = flt.application_id
--                              AND flt.lookup_type             = flv.lookup_type
--                              AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                              AND flv.lookup_type             = cv_xxcos1_order_edi_common
--                              AND flv.start_date_active      <= TRUNC( ld_sysdate )
--                              AND TRUNC( ld_sysdate )        <= NVL( flv.end_date_active, TRUNC( ld_sysdate ) )
--                              AND flv.enabled_flag            = cv_flag_yes
--                              AND flv.language                = USERENV( 'LANG' )
--                           ) flvs
--                         WHERE
--                             ottt.name      = flvs.order_l_type_name  -- �󒍃^�C�v�D���O���Q�ƃ^�C�v�D�󒍖��׃^�C�v��
                      FROM   fnd_lookup_values  flv
                      WHERE  flv.lookup_type   = cv_xxcos1_order_edi_common
                      AND    ld_sysdate        BETWEEN NVL( flv.start_date_active, ld_sysdate )
                                               AND     NVL( flv.end_date_active, ld_sysdate )
                      AND    flv.enabled_flag  = cv_flag_yes
                      AND    flv.language      = lv_language
                      AND    flv.attribute3    = ottt.name
/* 2009/08/11 Ver1.7 Mod End   */
                     )
--*** 2009/03/24 Ver1.3 MODIFY END   ***
/* 2009/04/24 Ver1.3 Add Start */
        AND   oola.order_quantity_uom   = muom.uom_code            -- �󒍖���.�󒍒P�ʁ��P�ʃ}�X�^.�P�ʃR�[�h
/* 2009/08/11 Ver1.7 Mod Start */
--        AND   muom.language             = USERENV('LANG')          -- �P�ʃ}�X�^.���ꁁ���{��
        AND   muom.language             = lv_language          -- �P�ʃ}�X�^.���ꁁ���{��
/* 2009/08/11 Ver1.7 Mod End   */
/* 2009/04/24 Ver1.3 Add End   */
        ;
--
        -- �Y�����ׂ���H
        IF ( lt_line_tab.COUNT <> 0 ) THEN
          -- �󒍖��׏��`�F�b�N
          <<line_check_loop>>
          FOR ln_line_cnt IN 1 .. lt_line_tab.COUNT LOOP
            -- ��Ԕ���敪��(1)��(n)�ňقȂ�ꍇ�A�G���[
            IF ( lt_line_tab(1).regular_sale_class <> lt_line_tab(ln_line_cnt).regular_sale_class ) THEN
/* 2009/07/13 Ver1.5 Add Start */
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application     => cv_xxcos_appl_short_nm
                              ,iv_name            => cv_msg_sales_class
                              ,iv_token_name1     => cv_tkn_order_no
                              ,iv_token_value1    => lt_head_tab(ln_head_cnt).cust_po_number
                              );
/* 2009/07/13 Ver1.5 Add End   */
              RAISE sale_class_expt;
            END IF;
            -- OUTBOUD�ۂ�'N'�̏ꍇ�A�G���[
            IF ( lt_line_tab(ln_line_cnt).outbound_flag = cv_flag_no ) THEN
/* 2009/07/13 Ver1.5 Add Start */
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application     => cv_xxcos_appl_short_nm
                              ,iv_name            => cv_msg_not_outbound
                              ,iv_token_name1     => cv_tkn_order_no
                              ,iv_token_value1    => lt_head_tab(ln_head_cnt).cust_po_number
                              ,iv_token_name2     => cv_tkn_line_no
                              ,iv_token_value2    => TO_CHAR( lt_line_tab(ln_line_cnt).line_number )
                              );
/* 2009/07/13 Ver1.5 Add End   */
              RAISE outbound_expt;
            END IF;
          END LOOP line_check_loop;
--
          -- �p�����[�^.��ԓ����敪�����ݒ� or ALL
          IF ( iv_regular_ar_sale_class IS NULL )
          OR ( iv_regular_ar_sale_class = cv_ras_class_all )
          THEN
            lv_sale_class_check := cv_flag_yes;      -- �Ώ�
          ELSE
            -- �p�����[�^.��ԓ����敪���󒍖���.��ԓ����敪
            IF ( iv_regular_ar_sale_class = lt_line_tab(1).regular_sale_class ) THEN
              lv_sale_class_check := cv_flag_yes;    -- �Ώ�
            ELSE
              lv_sale_class_check := cv_flag_no;     -- �ΏۊO
            END IF;
          END IF;
--
          -- ����敪�ΏہH
          IF ( lv_sale_class_check = cv_flag_yes ) THEN
            <<line_insert_loop>>
            FOR ln_line_cnt IN 1 .. lt_line_tab.COUNT LOOP
              -- �`�[�v
              IF ( lt_invoice_tab(ln_invoice_cnt).invoice_number <> lt_head_tab(ln_head_cnt).cust_po_number ) THEN
                ln_invoice_cnt := ln_invoice_cnt + 1;
                lt_invoice_tab(ln_invoice_cnt).invoice_number := lt_head_tab(ln_head_cnt).cust_po_number;
              END IF;
--
              ln_case_qty := 0;  -- �P�[�X��
              ln_bowl_qty := 0;  -- �{�[����
              ln_indv_qty := 0;  -- �o����
--
              CASE lt_line_tab(ln_line_cnt).order_quantity_uom
                WHEN cv_unit_case THEN  -- �P�[�X
                  ln_case_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- �o�א���(�P�[�X)
                  lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- �o�א���(���v�A�o��)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity
                     * TO_NUMBER( lt_line_tab(ln_line_cnt).num_of_case );
                WHEN cv_unit_bowl THEN  -- �{�[��
                  ln_bowl_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- �o�א���(�{�[��)
                  lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- �o�א���(���v�A�o��)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity
                     * lt_line_tab(ln_line_cnt).num_of_bowl;
                ELSE                    -- �o��
                  ln_indv_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- �o�א���(�o��)
                  lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- �o�א���(���v�A�o��)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
              END CASE;
--
              IF ( lt_head_edit_tab(ln_head_cnt).edi_header_info_id IS NULL ) THEN
                -- �w�b�_ID�̔�
                SELECT xxcos.xxcos_edi_headers_s01.NEXTVAL
                INTO   lt_head_edit_tab(ln_head_cnt).edi_header_info_id
                FROM   dual;
                -- �����敪
                lt_head_edit_tab(ln_head_cnt).ar_sale_class := lt_line_tab(1).regular_sale_class;
              END IF;
--
              -- ����ID�̔�
              SELECT xxcos.xxcos_edi_lines_s01.NEXTVAL
              INTO   ln_line_info_id
              FROM   dual;
--
              -- �i�ڕϊ�(EBS��EDI)
              xxcos_common2_pkg.conv_edi_item_code(
                   lt_head_tab(ln_head_cnt).edi_chain_code      -- EDI�`�F�[���X�R�[�h
                 , lt_line_tab(ln_line_cnt).ordered_item        -- �i�ڃR�[�h
                 , in_organization_id                           -- �݌ɑg�DID
                 , lt_line_tab(ln_line_cnt).order_quantity_uom  -- �P�ʃR�[�h
                 , lv_product_code2                             -- ���i�R�[�h�Q
                 , lv_jan_code                                  -- JAN�R�[�h
                 , lv_case_jan_code                             -- �P�[�XJAN�R�[�h
                 , lv_errbuf                                    -- �G���[�E���b�Z�[�W�G���[
                 , lv_retcode                                   -- ���^�[���E�R�[�h
                 , lv_errmsg                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              -- ���^�[���R�[�h������łȂ��ꍇ
              IF ( lv_retcode <> lv_ret_normal ) THEN
                ov_errbuf  := cv_prg_name || lv_errbuf;
                ov_errmsg  := lv_errmsg;
                RAISE item_conv_expt;
              END IF;
--
              -- EDI���׏��e�[�u���}��
              BEGIN
                INSERT INTO xxcos_edi_lines
                (
                  edi_line_info_id              -- EDI���׏��ID
                 ,edi_header_info_id            -- EDI�w�b�_���ID
                 ,line_no                       -- �s�m��
                 ,stockout_class                -- ���i�敪
                 ,stockout_reason               -- ���i���R
                 ,product_code_itouen           -- ���i�R�[�h(�ɓ���)
                 ,product_code1                 -- ���i�R�[�h�P
                 ,product_code2                 -- ���i�R�[�h�Q
                 ,jan_code                      -- �i�`�m�R�[�h
                 ,itf_code                      -- �h�s�e�R�[�h
                 ,extension_itf_code            -- �����h�s�e�R�[�h
                 ,case_product_code             -- �P�[�X���i�R�[�h
                 ,ball_product_code             -- �{�[�����i�R�[�h
                 ,product_code_item_type        -- ���i�R�[�h�i��
                 ,prod_class                    -- ���i�敪
                 ,product_name                  -- ���i��(����)
                 ,product_name1_alt             -- ���i���P(�J�i)
                 ,product_name2_alt             -- ���i���Q(�J�i)
                 ,item_standard1                -- �K�i�P
                 ,item_standard2                -- �K�i�Q
                 ,qty_in_case                   -- ����
                 ,num_of_cases                  -- �P�[�X����
                 ,num_of_ball                   -- �{�[������
                 ,item_color                    -- �F
                 ,item_size                     -- �T�C�Y
                 ,expiration_date               -- �ܖ�������
                 ,product_date                  -- ������
                 ,order_uom_qty                 -- �����P�ʐ�
                 ,shipping_uom_qty              -- �o�גP�ʐ�
                 ,packing_uom_qty               -- ����P�ʐ�
                 ,deal_code                     -- ����
                 ,deal_class                    -- �����敪
                 ,collation_code                -- �ƍ�
                 ,uom_code                      -- �P��
                 ,unit_price_class              -- �P���敪
                 ,parent_packing_number         -- �e����ԍ�
                 ,packing_number                -- ����ԍ�
                 ,product_group_code            -- ���i�Q�R�[�h
                 ,case_dismantle_flag           -- �P�[�X��̕s�t���O
                 ,case_class                    -- �P�[�X�敪
                 ,indv_order_qty                -- ��������(�o��)
                 ,case_order_qty                -- ��������(�P�[�X)
                 ,ball_order_qty                -- ��������(�{�[��)
                 ,sum_order_qty                 -- ��������(���v�A�o��)
                 ,indv_shipping_qty             -- �o�א���(�o��)
                 ,case_shipping_qty             -- �o�א���(�P�[�X)
                 ,ball_shipping_qty             -- �o�א���(�{�[��)
                 ,pallet_shipping_qty           -- �o�א���(�p���b�g)
                 ,sum_shipping_qty              -- �o�א���(���v�A�o��)
                 ,indv_stockout_qty             -- ���i����(�o��)
                 ,case_stockout_qty             -- ���i����(�P�[�X)
                 ,ball_stockout_qty             -- ���i����(�{�[��)
                 ,sum_stockout_qty              -- ���i����(���v�A�o��)
                 ,case_qty                      -- �P�[�X����
                 ,fold_container_indv_qty       -- �I���R��(�o��)����
                 ,order_unit_price              -- ���P��(����)
                 ,shipping_unit_price           -- ���P��(�o��)
                 ,order_cost_amt                -- �������z(����)
                 ,shipping_cost_amt             -- �������z(�o��)
                 ,stockout_cost_amt             -- �������z(���i)
                 ,selling_price                 -- ���P��
                 ,order_price_amt               -- �������z(����)
                 ,shipping_price_amt            -- �������z(�o��)
                 ,stockout_price_amt            -- �������z(���i)
                 ,a_column_department           -- �`��(�S�ݓX)
                 ,d_column_department           -- �c��(�S�ݓX)
                 ,standard_info_depth           -- �K�i���E���s��
                 ,standard_info_height          -- �K�i���E����
                 ,standard_info_width           -- �K�i���E��
                 ,standard_info_weight          -- �K�i���E�d��
                 ,general_succeeded_item1       -- �ėp���p�����ڂP
                 ,general_succeeded_item2       -- �ėp���p�����ڂQ
                 ,general_succeeded_item3       -- �ėp���p�����ڂR
                 ,general_succeeded_item4       -- �ėp���p�����ڂS
                 ,general_succeeded_item5       -- �ėp���p�����ڂT
                 ,general_succeeded_item6       -- �ėp���p�����ڂU
                 ,general_succeeded_item7       -- �ėp���p�����ڂV
                 ,general_succeeded_item8       -- �ėp���p�����ڂW
                 ,general_succeeded_item9       -- �ėp���p�����ڂX
                 ,general_succeeded_item10      -- �ėp���p�����ڂP�O
                 ,general_add_item1             -- �ėp�t�����ڂP
                 ,general_add_item2             -- �ėp�t�����ڂQ
                 ,general_add_item3             -- �ėp�t�����ڂR
                 ,general_add_item4             -- �ėp�t�����ڂS
                 ,general_add_item5             -- �ėp�t�����ڂT
                 ,general_add_item6             -- �ėp�t�����ڂU
                 ,general_add_item7             -- �ėp�t�����ڂV
                 ,general_add_item8             -- �ėp�t�����ڂW
                 ,general_add_item9             -- �ėp�t�����ڂX
                 ,general_add_item10            -- �ėp�t�����ڂP�O
                 ,chain_peculiar_area_line      -- �`�F�[���X�ŗL�G���A(����)
                 ,item_code                     -- �i�ڃR�[�h
                 ,line_uom                      -- ���גP��
                 ,hht_delivery_schedule_flag    -- HHT�[�i�\��A�g�σt���O
                 ,order_connection_line_number  -- �󒍊֘A���הԍ�
                 ,created_by                    -- �쐬��
                 ,creation_date                 -- �쐬��
                 ,last_updated_by               -- �ŏI�X�V��
                 ,last_update_date              -- �ŏI�X�V��
                 ,last_update_login             -- �ŏI�X�V���O�C��
                 ,request_id                    -- �v��ID
                 ,program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 ,program_id                    -- �R���J�����g�E�v���O����ID
                 ,program_update_date           -- �v���O�����X�V��
                ) VALUES (
                  ln_line_info_id                                  -- EDI���׏��ID
                 ,lt_head_edit_tab(ln_head_cnt).edi_header_info_id -- EDI�w�b�_���ID
                 ,lt_line_tab(ln_line_cnt).line_number             -- �s�m��
                 ,cv_stockout_class                                -- ���i�敪
                 ,NULL                                             -- ���i���R
                 ,lt_line_tab(ln_line_cnt).ordered_item            -- ���i�R�[�h(�ɓ���)
                 ,NULL                                             -- ���i�R�[�h�P
                 ,lv_product_code2                                 -- ���i�R�[�h�Q
                 ,lt_line_tab(ln_line_cnt).jan_code                -- �i�`�m�R�[�h
                 ,lt_line_tab(ln_line_cnt).itf_code                -- �h�s�e�R�[�h
                 ,NULL                                             -- �����h�s�e�R�[�h
                 ,NULL                                             -- �P�[�X���i�R�[�h
                 ,NULL                                             -- �{�[�����i�R�[�h
                 ,NULL                                             -- ���i�R�[�h�i��
                 ,NULL                                             -- ���i�敪
/* 2009/03/03 Ver1.1 Mod Start */
--               ,NULL                                             -- ���i��(����)
                 ,SUBSTRB(lt_line_tab(ln_line_cnt).item_name, 1, 60)     -- ���i��(����)
                 ,NULL                                             -- ���i���P(�J�i)
--               ,NULL                                             -- ���i���Q(�J�i)
                 ,SUBSTRB(lt_line_tab(ln_line_cnt).item_name_alt, 1, 15) -- ���i���Q(�J�i)
/* 2009/03/03 Ver1.1 Mod  End  */
                 ,NULL                                             -- �K�i�P
                 ,NULL                                             -- �K�i�Q
                 ,NULL                                             -- ����
                 ,lt_line_tab(ln_line_cnt).num_of_case             -- �P�[�X����
                 ,lt_line_tab(ln_line_cnt).num_of_bowl             -- �{�[������
                 ,NULL                                             -- �F
                 ,NULL                                             -- �T�C�Y
                 ,NULL                                             -- �ܖ�������
                 ,NULL                                             -- ������
                 ,NULL                                             -- �����P�ʐ�
                 ,NULL                                             -- �o�גP�ʐ�
                 ,NULL                                             -- ����P�ʐ�
                 ,NULL                                             -- ����
                 ,NULL                                             -- �����敪
                 ,NULL                                             -- �ƍ�
/* 2009/04/24 Ver1.3 Mod Start */
--                 ,lt_line_tab(ln_line_cnt).order_quantity_uom      -- �P��
                 ,lt_line_tab(ln_line_cnt).edi_rep_uom             -- �P��
/* 2009/04/24 Ver1.3 Mod End   */
                 ,NULL                                             -- �P���敪
                 ,NULL                                             -- �e����ԍ�
                 ,NULL                                             -- ����ԍ�
                 ,NULL                                             -- ���i�Q�R�[�h
                 ,NULL                                             -- �P�[�X��̕s�t���O
                 ,NULL                                             -- �P�[�X�敪
                 ,ln_indv_qty                                      -- ��������(�o��)
                 ,ln_case_qty                                      -- ��������(�P�[�X)
                 ,ln_bowl_qty                                      -- ��������(�{�[��)
                 ,lt_line_tab(ln_line_cnt).ordered_quantity        -- ��������(���v�A�o��)
                 ,ln_indv_qty                                      -- �o�א���(�o��)
                 ,ln_case_qty                                      -- �o�א���(�P�[�X)
                 ,ln_bowl_qty                                      -- �o�א���(�{�[��)
                 ,NULL                                             -- �o�א���(�p���b�g)
                 ,lt_line_tab(ln_line_cnt).ordered_quantity        -- �o�א���(���v�A�o��)
                 ,0                                                -- ���i����(�o��)
                 ,0                                                -- ���i����(�P�[�X)
                 ,0                                                -- ���i����(�{�[��)
                 ,0                                                -- ���i����(���v�A�o��)
                 ,NULL                                             -- �P�[�X����
                 ,NULL                                             -- �I���R��(�o��)����
                 ,lt_line_tab(ln_line_cnt).unit_selling_price      -- ���P��(����)
                 ,lt_line_tab(ln_line_cnt).unit_selling_price      -- ���P��(�o��)
                 ,NULL                                             -- �������z(����)
                 ,NULL                                             -- �������z(�o��)
                 ,NULL                                             -- �������z(���i)
/* 2010/03/09 Ver1.8 Mod Start */
--                 ,NULL                                             -- ���P��
--                 ,NULL                                             -- �������z(����)
                 ,lt_line_tab(ln_line_cnt).selling_price           -- ���P��
                 ,lt_line_tab(ln_line_cnt).order_price_amt         -- �������z(����)
/* 2010/03/09 Ver1.8 Mod  End  */
                 ,NULL                                             -- �������z(�o��)
                 ,NULL                                             -- �������z(���i)
                 ,NULL                                             -- �`��(�S�ݓX)
                 ,NULL                                             -- �c��(�S�ݓX)
                 ,NULL                                             -- �K�i���E���s��
                 ,NULL                                             -- �K�i���E����
                 ,NULL                                             -- �K�i���E��
                 ,NULL                                             -- �K�i���E�d��
                 ,NULL                                             -- �ėp���p�����ڂP
                 ,NULL                                             -- �ėp���p�����ڂQ
                 ,NULL                                             -- �ėp���p�����ڂR
                 ,NULL                                             -- �ėp���p�����ڂS
                 ,NULL                                             -- �ėp���p�����ڂT
                 ,NULL                                             -- �ėp���p�����ڂU
                 ,NULL                                             -- �ėp���p�����ڂV
                 ,NULL                                             -- �ėp���p�����ڂW
                 ,NULL                                             -- �ėp���p�����ڂX
                 ,NULL                                             -- �ėp���p�����ڂP�O
                 ,NULL                                             -- �ėp�t�����ڂP
                 ,NULL                                             -- �ėp�t�����ڂQ
                 ,NULL                                             -- �ėp�t�����ڂR
                 ,NULL                                             -- �ėp�t�����ڂS
                 ,NULL                                             -- �ėp�t�����ڂT
                 ,NULL                                             -- �ėp�t�����ڂU
                 ,NULL                                             -- �ėp�t�����ڂV
                 ,NULL                                             -- �ėp�t�����ڂW
                 ,NULL                                             -- �ėp�t�����ڂX
                 ,NULL                                             -- �ėp�t�����ڂP�O
                 ,NULL                                             -- �`�F�[���X�ŗL�G���A(����)
                 ,lt_line_tab(ln_line_cnt).ordered_item            -- �i�ڃR�[�h
                 ,lt_line_tab(ln_line_cnt).order_quantity_uom      -- ���גP��
                 ,cv_flag_no                                       -- HHT�[�i�\��A�g�σt���O
                 ,lt_line_tab(ln_line_cnt).orig_sys_line_refw      -- �󒍊֘A���הԍ�
                 ,ln_user_id                                       -- �쐬��
                 ,SYSDATE                                          -- �쐬��
                 ,ln_user_id                                       -- �ŏI�X�V��
                 ,SYSDATE                                          -- �ŏI�X�V��
                 ,ln_login_id                                      -- �ŏI�X�V���O�C��
                 ,NULL                                             -- �v��ID
                 ,NULL                                             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 ,NULL                                             -- �R���J�����g�E�v���O����ID
                 ,NULL                                             -- �v���O�����X�V��
                );
              EXCEPTION
                WHEN OTHERS THEN
                  lv_table_name := cv_tbl_name_line;
                  RAISE table_insert_expt;
              END;
--
            END LOOP line_insert_loop;
          END IF;      -- ����敪�ΏہH
        END IF;        -- �Y�����ׂ���H
      END IF;          -- ��荞�ݍς݁H
    END LOOP head_proc_loop;
--
    ln_invoice_cnt := 1;
    <<head_insert_loop>>
    FOR ln_head_cnt IN 1 .. lt_head_tab.COUNT LOOP
      -- �w�b�_�����ΏہH
      IF ( lt_head_edit_tab(ln_head_cnt).edi_header_info_id IS NOT NULL ) THEN
        -- �`�[�v
        IF ( lt_invoice_tab(ln_invoice_cnt).invoice_number <> lt_head_tab(ln_head_cnt).cust_po_number ) THEN
          ln_invoice_cnt := ln_invoice_cnt + 1;
        END IF;
--
        -- EDI�w�b�_���e�[�u���}��
        BEGIN
          INSERT INTO xxcos_edi_headers
          (
            edi_header_info_id            -- EDI�w�b�_���ID
           ,medium_class                  -- �}�̋敪
           ,data_type_code                -- �f�[�^��R�[�h
           ,file_no                       -- �t�@�C���m��
           ,info_class                    -- ���敪
           ,process_date                  -- ������
           ,process_time                  -- ��������
           ,base_code                     -- ���_(����)�R�[�h
           ,base_name                     -- ���_��(������)
           ,base_name_alt                 -- ���_��(�J�i)
           ,edi_chain_code                -- �d�c�h�`�F�[���X�R�[�h
           ,edi_chain_name                -- �d�c�h�`�F�[���X��(����)
           ,edi_chain_name_alt            -- �d�c�h�`�F�[���X��(�J�i)
           ,chain_code                    -- �`�F�[���X�R�[�h
           ,chain_name                    -- �`�F�[���X��(����)
           ,chain_name_alt                -- �`�F�[���X��(�J�i)
           ,report_code                   -- ���[�R�[�h
           ,report_show_name              -- ���[�\����
           ,customer_code                 -- �ڋq�R�[�h
           ,customer_name                 -- �ڋq��(����)
           ,customer_name_alt             -- �ڋq��(�J�i)
           ,company_code                  -- �ЃR�[�h
           ,company_name                  -- �Ж�(����)
           ,company_name_alt              -- �Ж�(�J�i)
           ,shop_code                     -- �X�R�[�h
           ,shop_name                     -- �X��(����)
           ,shop_name_alt                 -- �X��(�J�i)
           ,delivery_center_code          -- �[���Z���^�[�R�[�h
           ,delivery_center_name          -- �[���Z���^�[��(����)
           ,delivery_center_name_alt      -- �[���Z���^�[��(�J�i)
           ,order_date                    -- ������
           ,center_delivery_date          -- �Z���^�[�[�i��
           ,result_delivery_date          -- ���[�i��
           ,shop_delivery_date            -- �X�ܔ[�i��
           ,data_creation_date_edi_data   -- �f�[�^�쐬��(�d�c�h�f�[�^��)
           ,data_creation_time_edi_data   -- �f�[�^�쐬����(�d�c�h�f�[�^��)
           ,invoice_class                 -- �`�[�敪
           ,small_classification_code     -- �����ރR�[�h
           ,small_classification_name     -- �����ޖ�
           ,middle_classification_code    -- �����ރR�[�h
           ,middle_classification_name    -- �����ޖ�
           ,big_classification_code       -- �啪�ރR�[�h
           ,big_classification_name       -- �啪�ޖ�
           ,other_party_department_code   -- ����敔��R�[�h
           ,other_party_order_number      -- ����攭���ԍ�
           ,check_digit_class             -- �`�F�b�N�f�W�b�g�L���敪
           ,invoice_number                -- �`�[�ԍ�
           ,check_digit                   -- �`�F�b�N�f�W�b�g
           ,close_date                    -- ����
           ,order_no_ebs                  -- �󒍂m��(�d�a�r)
           ,ar_sale_class                 -- �����敪
           ,delivery_classe               -- �z���敪
           ,opportunity_no                -- �ւm��
           ,contact_to                    -- �A����
           ,route_sales                   -- ���[�g�Z�[���X
           ,corporate_code                -- �@�l�R�[�h
           ,maker_name                    -- ���[�J�[��
           ,area_code                     -- �n��R�[�h
           ,area_name                     -- �n�於(����)
           ,area_name_alt                 -- �n�於(�J�i)
           ,vendor_code                   -- �����R�[�h
           ,vendor_name                   -- ����於(����)
           ,vendor_name1_alt              -- ����於�P(�J�i)
           ,vendor_name2_alt              -- ����於�Q(�J�i)
           ,vendor_tel                    -- �����s�d�k
           ,vendor_charge                 -- �����S����
           ,vendor_address                -- �����Z��(����)
           ,deliver_to_code_itouen        -- �͂���R�[�h(�ɓ���)
           ,deliver_to_code_chain         -- �͂���R�[�h(�`�F�[���X)
           ,deliver_to                    -- �͂���(����)
           ,deliver_to1_alt               -- �͂���P(�J�i)
           ,deliver_to2_alt               -- �͂���Q(�J�i)
           ,deliver_to_address            -- �͂���Z��(����)
           ,deliver_to_address_alt        -- �͂���Z��(�J�i)
           ,deliver_to_tel                -- �͂���s�d�k
           ,balance_accounts_code         -- ������R�[�h
           ,balance_accounts_company_code -- ������ЃR�[�h
           ,balance_accounts_shop_code    -- ������X�R�[�h
           ,balance_accounts_name         -- �����於(����)
           ,balance_accounts_name_alt     -- �����於(�J�i)
           ,balance_accounts_address      -- ������Z��(����)
           ,balance_accounts_address_alt  -- ������Z��(�J�i)
           ,balance_accounts_tel          -- ������s�d�k
           ,order_possible_date           -- �󒍉\��
           ,permission_possible_date      -- ���e�\��
           ,forward_month                 -- ����N����
           ,payment_settlement_date       -- �x�����ϓ�
           ,handbill_start_date_active    -- �`���V�J�n��
           ,billing_due_date              -- ��������
           ,shipping_time                 -- �o�׎���
           ,delivery_schedule_time        -- �[�i�\�莞��
           ,order_time                    -- ��������
           ,general_date_item1            -- �ėp���t���ڂP
           ,general_date_item2            -- �ėp���t���ڂQ
           ,general_date_item3            -- �ėp���t���ڂR
           ,general_date_item4            -- �ėp���t���ڂS
           ,general_date_item5            -- �ėp���t���ڂT
           ,arrival_shipping_class        -- ���o�׋敪
           ,vendor_class                  -- �����敪
           ,invoice_detailed_class        -- �`�[����敪
           ,unit_price_use_class          -- �P���g�p�敪
           ,sub_distribution_center_code  -- �T�u�����Z���^�[�R�[�h
           ,sub_distribution_center_name  -- �T�u�����Z���^�[�R�[�h��
           ,center_delivery_method        -- �Z���^�[�[�i���@
           ,center_use_class              -- �Z���^�[���p�敪
           ,center_whse_class             -- �Z���^�[�q�ɋ敪
           ,center_area_class             -- �Z���^�[�n��敪
           ,center_arrival_class          -- �Z���^�[���׋敪
           ,depot_class                   -- �f�|�敪
           ,tcdc_class                    -- �s�b�c�b�敪
           ,upc_flag                      -- �t�o�b�t���O
           ,simultaneously_class          -- ��ċ敪
           ,business_id                   -- �Ɩ��h�c
           ,whse_directly_class           -- �q���敪
           ,premium_rebate_class          -- �i�i���ߋ敪
           ,item_type                     -- ���ڎ��
           ,cloth_house_food_class        -- �߉ƐH�敪
           ,mix_class                     -- ���݋敪
           ,stk_class                     -- �݌ɋ敪
           ,last_modify_site_class        -- �ŏI�C���ꏊ�敪
           ,report_class                  -- ���[�敪
           ,addition_plan_class           -- �ǉ��E�v��敪
           ,registration_class            -- �o�^�敪
           ,specific_class                -- ����敪
           ,dealings_class                -- ����敪
           ,order_class                   -- �����敪
           ,sum_line_class                -- �W�v���׋敪
           ,shipping_guidance_class       -- �o�׈ē��ȊO�敪
           ,shipping_class                -- �o�׋敪
           ,product_code_use_class        -- ���i�R�[�h�g�p�敪
           ,cargo_item_class              -- �ϑ��i�敪
           ,ta_class                      -- �s�^�`�敪
           ,plan_code                     -- ���R�[�h
           ,category_code                 -- �J�e�S���[�R�[�h
           ,category_class                -- �J�e�S���[�敪
           ,carrier_means                 -- �^����i
           ,counter_code                  -- ����R�[�h
           ,move_sign                     -- �ړ��T�C��
           ,eos_handwriting_class         -- �d�n�r�E�菑�敪
           ,delivery_to_section_code      -- �[�i��ۃR�[�h
           ,invoice_detailed              -- �`�[����
           ,attach_qty                    -- �Y�t��
           ,other_party_floor             -- �t���A
           ,text_no                       -- �s�d�w�s�m��
           ,in_store_code                 -- �C���X�g�A�R�[�h
           ,tag_data                      -- �^�O
           ,competition_code              -- ����
           ,billing_chair                 -- ��������
           ,chain_store_code              -- �`�F�[���X�g�A�[�R�[�h
           ,chain_store_short_name        -- �`�F�[���X�g�A�[�R�[�h��������
           ,direct_delivery_rcpt_fee      -- ���z���^���旿
           ,bill_info                     -- ��`���
           ,description                   -- �E�v
           ,interior_code                 -- �����R�[�h
           ,order_info_delivery_category  -- ������� �[�i�J�e�S���[
           ,purchase_type                 -- �d���`��
           ,delivery_to_name_alt          -- �[�i�ꏊ��(�J�i)
           ,shop_opened_site              -- �X�o�ꏊ
           ,counter_name                  -- ���ꖼ
           ,extension_number              -- �����ԍ�
           ,charge_name                   -- �S���Җ�
           ,price_tag                     -- �l�D
           ,tax_type                      -- �Ŏ�
           ,consumption_tax_class         -- ����ŋ敪
           ,brand_class                   -- �a�q
           ,id_code                       -- �h�c�R�[�h
           ,department_code               -- �S�ݓX�R�[�h
           ,department_name               -- �S�ݓX��
           ,item_type_number              -- �i�ʔԍ�
           ,description_department        -- �E�v(�S�ݓX)
           ,price_tag_method              -- �l�D���@
           ,reason_column                 -- ���R��
           ,a_column_header               -- �`���w�b�_
           ,d_column_header               -- �c���w�b�_
           ,brand_code                    -- �u�����h�R�[�h
           ,line_code                     -- ���C���R�[�h
           ,class_code                    -- �N���X�R�[�h
           ,a1_column                     -- �`�|�P��
           ,b1_column                     -- �a�|�P��
           ,c1_column                     -- �b�|�P��
           ,d1_column                     -- �c�|�P��
           ,e1_column                     -- �d�|�P��
           ,a2_column                     -- �`�|�Q��
           ,b2_column                     -- �a�|�Q��
           ,c2_column                     -- �b�|�Q��
           ,d2_column                     -- �c�|�Q��
           ,e2_column                     -- �d�|�Q��
           ,a3_column                     -- �`�|�R��
           ,b3_column                     -- �a�|�R��
           ,c3_column                     -- �b�|�R��
           ,d3_column                     -- �c�|�R��
           ,e3_column                     -- �d�|�R��
           ,f1_column                     -- �e�|�P��
           ,g1_column                     -- �f�|�P��
           ,h1_column                     -- �g�|�P��
           ,i1_column                     -- �h�|�P��
           ,j1_column                     -- �i�|�P��
           ,k1_column                     -- �j�|�P��
           ,l1_column                     -- �k�|�P��
           ,f2_column                     -- �e�|�Q��
           ,g2_column                     -- �f�|�Q��
           ,h2_column                     -- �g�|�Q��
           ,i2_column                     -- �h�|�Q��
           ,j2_column                     -- �i�|�Q��
           ,k2_column                     -- �j�|�Q��
           ,l2_column                     -- �k�|�Q��
           ,f3_column                     -- �e�|�R��
           ,g3_column                     -- �f�|�R��
           ,h3_column                     -- �g�|�R��
           ,i3_column                     -- �h�|�R��
           ,j3_column                     -- �i�|�R��
           ,k3_column                     -- �j�|�R��
           ,l3_column                     -- �k�|�R��
           ,chain_peculiar_area_header    -- �`�F�[���X�ŗL�G���A(�w�b�_�[)
           ,order_connection_number       -- �󒍊֘A�ԍ�
           ,invoice_indv_order_qty        -- (�`�[�v)��������(�o��)
           ,invoice_case_order_qty        -- (�`�[�v)��������(�P�[�X)
           ,invoice_ball_order_qty        -- (�`�[�v)��������(�{�[��)
           ,invoice_sum_order_qty         -- (�`�[�v)��������(���v�A�o��)
           ,invoice_indv_shipping_qty     -- (�`�[�v)�o�א���(�o��)
           ,invoice_case_shipping_qty     -- (�`�[�v)�o�א���(�P�[�X)
           ,invoice_ball_shipping_qty     -- (�`�[�v)�o�א���(�{�[��)
           ,invoice_pallet_shipping_qty   -- (�`�[�v)�o�א���(�p���b�g)
           ,invoice_sum_shipping_qty      -- (�`�[�v)�o�א���(���v�A�o��)
           ,invoice_indv_stockout_qty     -- (�`�[�v)���i����(�o��)
           ,invoice_case_stockout_qty     -- (�`�[�v)���i����(�P�[�X)
           ,invoice_ball_stockout_qty     -- (�`�[�v)���i����(�{�[��)
           ,invoice_sum_stockout_qty      -- (�`�[�v)���i����(���v�A�o��)
           ,invoice_case_qty              -- (�`�[�v)�P�[�X����
           ,invoice_fold_container_qty    -- (�`�[�v)�I���R��(�o��)����
           ,invoice_order_cost_amt        -- (�`�[�v)�������z(����)
           ,invoice_shipping_cost_amt     -- (�`�[�v)�������z(�o��)
           ,invoice_stockout_cost_amt     -- (�`�[�v)�������z(���i)
           ,invoice_order_price_amt       -- (�`�[�v)�������z(����)
           ,invoice_shipping_price_amt    -- (�`�[�v)�������z(�o��)
           ,invoice_stockout_price_amt    -- (�`�[�v)�������z(���i)
           ,total_indv_order_qty          -- (�����v)��������(�o��)
           ,total_case_order_qty          -- (�����v)��������(�P�[�X)
           ,total_ball_order_qty          -- (�����v)��������(�{�[��)
           ,total_sum_order_qty           -- (�����v)��������(���v�A�o��)
           ,total_indv_shipping_qty       -- (�����v)�o�א���(�o��)
           ,total_case_shipping_qty       -- (�����v)�o�א���(�P�[�X)
           ,total_ball_shipping_qty       -- (�����v)�o�א���(�{�[��)
           ,total_pallet_shipping_qty     -- (�����v)�o�א���(�p���b�g)
           ,total_sum_shipping_qty        -- (�����v)�o�א���(���v�A�o��)
           ,total_indv_stockout_qty       -- (�����v)���i����(�o��)
           ,total_case_stockout_qty       -- (�����v)���i����(�P�[�X)
           ,total_ball_stockout_qty       -- (�����v)���i����(�{�[��)
           ,total_sum_stockout_qty        -- (�����v)���i����(���v�A�o��)
           ,total_case_qty                -- (�����v)�P�[�X����
           ,total_fold_container_qty      -- (�����v)�I���R��(�o��)����
           ,total_order_cost_amt          -- (�����v)�������z(����)
           ,total_shipping_cost_amt       -- (�����v)�������z(�o��)
           ,total_stockout_cost_amt       -- (�����v)�������z(���i)
           ,total_order_price_amt         -- (�����v)�������z(����)
           ,total_shipping_price_amt      -- (�����v)�������z(�o��)
           ,total_stockout_price_amt      -- (�����v)�������z(���i)
           ,total_line_qty                -- �g�[�^���s��
           ,total_invoice_qty             -- �g�[�^���`�[����
           ,chain_peculiar_area_footer    -- �`�F�[���X�ŗL�G���A(�t�b�^�[)
           ,conv_customer_code            -- �ύX��ڋq�R�[�h
           ,order_forward_flag            -- �󒍘A�g�σt���O
           ,creation_class                -- �쐬���敪
           ,edi_delivery_schedule_flag    -- EDI�[�i�\�著�M�σt���O
           ,price_list_header_id          -- ���i�\�w�b�_ID
           ,created_by                    -- �쐬��
           ,creation_date                 -- �쐬��
           ,last_updated_by               -- �ŏI�X�V��
           ,last_update_date              -- �ŏI�X�V��
           ,last_update_login             -- �ŏI�X�V���O�C��
           ,request_id                    -- �v��ID
           ,program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                    -- �R���J�����g�E�v���O����ID
           ,program_update_date           -- �v���O�����X�V��
           ) VALUES (
            lt_head_edit_tab(ln_head_cnt).edi_header_info_id            -- EDI�w�b�_���ID
           ,cv_medium_class                                             -- �}�̋敪
           ,cv_data_type_code                                           -- �f�[�^��R�[�h
           ,cv_file_no                                                  -- �t�@�C���m��
           ,NULL                                                        -- ���敪
           ,NULL                                                        -- ������
           ,NULL                                                        -- ��������
           ,lt_head_tab(ln_head_cnt).base_code                          -- ���_(����)�R�[�h
           ,lt_head_tab(ln_head_cnt).base_name                          -- ���_��(������)
           ,lt_head_tab(ln_head_cnt).base_name_alt                      -- ���_��(�J�i)
           ,lt_head_tab(ln_head_cnt).edi_chain_code                     -- �d�c�h�`�F�[���X�R�[�h
           ,lt_head_tab(ln_head_cnt).edi_chain_name                     -- �d�c�h�`�F�[���X��(����)
           ,lt_head_tab(ln_head_cnt).edi_chain_name_alt                 -- �d�c�h�`�F�[���X��(�J�i)
           ,NULL                                                        -- �`�F�[���X�R�[�h
           ,NULL                                                        -- �`�F�[���X��(����)
           ,NULL                                                        -- �`�F�[���X��(�J�i)
           ,NULL                                                        -- ���[�R�[�h
           ,NULL                                                        -- ���[�\����
           ,lt_head_tab(ln_head_cnt).account_number                     -- �ڋq�R�[�h
           ,lt_head_tab(ln_head_cnt).customer_name                      -- �ڋq��(����)
           ,lt_head_tab(ln_head_cnt).customer_name_alt                  -- �ڋq��(�J�i)
           ,NULL                                                        -- �ЃR�[�h
           ,NULL                                                        -- �Ж�(����)
           ,NULL                                                        -- �Ж�(�J�i)
           ,lt_head_tab(ln_head_cnt).store_code                         -- �X�R�[�h
           ,lt_head_tab(ln_head_cnt).cust_store_name                    -- �X��(����)
           ,NULL                                                        -- �X��(�J�i)
           ,NULL                                                        -- �[���Z���^�[�R�[�h
           ,NULL                                                        -- �[���Z���^�[��(����)
           ,NULL                                                        -- �[���Z���^�[��(�J�i)
           ,lt_head_tab(ln_head_cnt).ordered_date                       -- ������
           ,lt_head_tab(ln_head_cnt).request_date                       -- �Z���^�[�[�i��
           ,NULL                                                        -- ���[�i��
           ,lt_head_tab(ln_head_cnt).request_date                       -- �X�ܔ[�i��
           ,NULL                                                        -- �f�[�^�쐬��(�d�c�h�f�[�^��)
           ,NULL                                                        -- �f�[�^�쐬����(�d�c�h�f�[�^��)
/* 2009/07/14 Ver1.6 Mod Start */
--           ,NULL                                                        -- �`�[�敪
           ,lt_head_tab(ln_head_cnt).invoice_class                      -- �`�[�敪
/* 2009/07/14 Ver1.6 Mod End   */
           ,NULL                                                        -- �����ރR�[�h
           ,NULL                                                        -- �����ޖ�
           ,NULL                                                        -- �����ރR�[�h
           ,NULL                                                        -- �����ޖ�
/* 2009/07/14 Ver1.6 Mod Start */
--           ,NULL                                                        -- �啪�ރR�[�h
           ,lt_head_tab(ln_head_cnt).classification_code                -- �啪�ރR�[�h
/* 2009/07/14 Ver1.6 Mod End   */
           ,NULL                                                        -- �啪�ޖ�
           ,NULL                                                        -- ����敔��R�[�h
           ,NULL                                                        -- ����攭���ԍ�
           ,NULL                                                        -- �`�F�b�N�f�W�b�g�L���敪
           ,lt_head_tab(ln_head_cnt).cust_po_number                     -- �`�[�ԍ�
           ,NULL                                                        -- �`�F�b�N�f�W�b�g
           ,NULL                                                        -- ����
           ,lt_head_tab(ln_head_cnt).order_number                       -- �󒍂m��(�d�a�r)
           ,lt_head_edit_tab(ln_head_cnt).ar_sale_class                 -- �����敪
           ,NULL                                                        -- �z���敪
           ,NULL                                                        -- �ւm��
           ,NULL                                                        -- �A����
           ,NULL                                                        -- ���[�g�Z�[���X
           ,NULL                                                        -- �@�l�R�[�h
           ,NULL                                                        -- ���[�J�[��
           ,lt_head_tab(ln_head_cnt).edi_district_code                  -- �n��R�[�h
           ,lt_head_tab(ln_head_cnt).edi_district_name                  -- �n�於(����)
           ,lt_head_tab(ln_head_cnt).edi_district_kana                  -- �n�於(�J�i)
           ,NULL                                                        -- �����R�[�h
           ,NULL                                                        -- ����於(����)
           ,NULL                                                        -- ����於�P(�J�i)
           ,NULL                                                        -- ����於�Q(�J�i)
           ,NULL                                                        -- �����s�d�k
           ,NULL                                                        -- �����S����
           ,NULL                                                        -- �����Z��(����)
           ,NULL                                                        -- �͂���R�[�h(�ɓ���)
           ,NULL                                                        -- �͂���R�[�h(�`�F�[���X)
           ,NULL                                                        -- �͂���(����)
           ,NULL                                                        -- �͂���P(�J�i)
           ,NULL                                                        -- �͂���Q(�J�i)
           ,NULL                                                        -- �͂���Z��(����)
           ,NULL                                                        -- �͂���Z��(�J�i)
           ,NULL                                                        -- �͂���s�d�k
           ,NULL                                                        -- ������R�[�h
           ,NULL                                                        -- ������ЃR�[�h
           ,NULL                                                        -- ������X�R�[�h
           ,NULL                                                        -- �����於(����)
           ,NULL                                                        -- �����於(�J�i)
           ,NULL                                                        -- ������Z��(����)
           ,NULL                                                        -- ������Z��(�J�i)
           ,NULL                                                        -- ������s�d�k
           ,NULL                                                        -- �󒍉\��
           ,NULL                                                        -- ���e�\��
           ,NULL                                                        -- ����N����
           ,NULL                                                        -- �x�����ϓ�
           ,NULL                                                        -- �`���V�J�n��
           ,NULL                                                        -- ��������
           ,NULL                                                        -- �o�׎���
           ,NULL                                                        -- �[�i�\�莞��
           ,NULL                                                        -- ��������
           ,NULL                                                        -- �ėp���t���ڂP
           ,NULL                                                        -- �ėp���t���ڂQ
           ,NULL                                                        -- �ėp���t���ڂR
           ,NULL                                                        -- �ėp���t���ڂS
           ,NULL                                                        -- �ėp���t���ڂT
           ,NULL                                                        -- ���o�׋敪
           ,NULL                                                        -- �����敪
           ,NULL                                                        -- �`�[����敪
           ,NULL                                                        -- �P���g�p�敪
           ,NULL                                                        -- �T�u�����Z���^�[�R�[�h
           ,NULL                                                        -- �T�u�����Z���^�[�R�[�h��
           ,NULL                                                        -- �Z���^�[�[�i���@
           ,NULL                                                        -- �Z���^�[���p�敪
           ,NULL                                                        -- �Z���^�[�q�ɋ敪
           ,NULL                                                        -- �Z���^�[�n��敪
           ,NULL                                                        -- �Z���^�[���׋敪
           ,NULL                                                        -- �f�|�敪
           ,NULL                                                        -- �s�b�c�b�敪
           ,NULL                                                        -- �t�o�b�t���O
           ,NULL                                                        -- ��ċ敪
           ,NULL                                                        -- �Ɩ��h�c
           ,NULL                                                        -- �q���敪
           ,NULL                                                        -- �i�i���ߋ敪
           ,NULL                                                        -- ���ڎ��
           ,NULL                                                        -- �߉ƐH�敪
           ,NULL                                                        -- ���݋敪
           ,NULL                                                        -- �݌ɋ敪
           ,NULL                                                        -- �ŏI�C���ꏊ�敪
           ,NULL                                                        -- ���[�敪
           ,NULL                                                        -- �ǉ��E�v��敪
           ,NULL                                                        -- �o�^�敪
           ,NULL                                                        -- ����敪
           ,NULL                                                        -- ����敪
           ,NULL                                                        -- �����敪
           ,NULL                                                        -- �W�v���׋敪
           ,NULL                                                        -- �o�׈ē��ȊO�敪
           ,NULL                                                        -- �o�׋敪
           ,NULL                                                        -- ���i�R�[�h�g�p�敪
           ,NULL                                                        -- �ϑ��i�敪
           ,NULL                                                        -- �s�^�`�敪
           ,NULL                                                        -- ���R�[�h
           ,NULL                                                        -- �J�e�S���[�R�[�h
           ,NULL                                                        -- �J�e�S���[�敪
           ,NULL                                                        -- �^����i
           ,NULL                                                        -- ����R�[�h
           ,NULL                                                        -- �ړ��T�C��
           ,NULL                                                        -- �d�n�r�E�菑�敪
           ,NULL                                                        -- �[�i��ۃR�[�h
           ,NULL                                                        -- �`�[����
           ,NULL                                                        -- �Y�t��
           ,NULL                                                        -- �t���A
           ,NULL                                                        -- �s�d�w�s�m��
           ,NULL                                                        -- �C���X�g�A�R�[�h
           ,NULL                                                        -- �^�O
           ,NULL                                                        -- ����
           ,NULL                                                        -- ��������
           ,NULL                                                        -- �`�F�[���X�g�A�[�R�[�h
           ,NULL                                                        -- �`�F�[���X�g�A�[�R�[�h��������
           ,NULL                                                        -- ���z���^���旿
           ,NULL                                                        -- ��`���
           ,NULL                                                        -- �E�v
           ,NULL                                                        -- �����R�[�h
           ,NULL                                                        -- ������� �[�i�J�e�S���[
           ,NULL                                                        -- �d���`��
           ,NULL                                                        -- �[�i�ꏊ��(�J�i)
           ,NULL                                                        -- �X�o�ꏊ
           ,NULL                                                        -- ���ꖼ
           ,NULL                                                        -- �����ԍ�
           ,NULL                                                        -- �S���Җ�
           ,NULL                                                        -- �l�D
           ,NULL                                                        -- �Ŏ�
           ,NULL                                                        -- ����ŋ敪
           ,NULL                                                        -- �a�q
           ,NULL                                                        -- �h�c�R�[�h
           ,NULL                                                        -- �S�ݓX�R�[�h
           ,NULL                                                        -- �S�ݓX��
           ,NULL                                                        -- �i�ʔԍ�
           ,NULL                                                        -- �E�v(�S�ݓX)
           ,NULL                                                        -- �l�D���@
           ,NULL                                                        -- ���R��
           ,NULL                                                        -- �`���w�b�_
           ,NULL                                                        -- �c���w�b�_
           ,NULL                                                        -- �u�����h�R�[�h
           ,NULL                                                        -- ���C���R�[�h
           ,NULL                                                        -- �N���X�R�[�h
           ,NULL                                                        -- �`�|�P��
           ,NULL                                                        -- �a�|�P��
           ,NULL                                                        -- �b�|�P��
           ,NULL                                                        -- �c�|�P��
           ,NULL                                                        -- �d�|�P��
           ,NULL                                                        -- �`�|�Q��
           ,NULL                                                        -- �a�|�Q��
           ,NULL                                                        -- �b�|�Q��
           ,NULL                                                        -- �c�|�Q��
           ,NULL                                                        -- �d�|�Q��
           ,NULL                                                        -- �`�|�R��
           ,NULL                                                        -- �a�|�R��
           ,NULL                                                        -- �b�|�R��
           ,NULL                                                        -- �c�|�R��
           ,NULL                                                        -- �d�|�R��
           ,NULL                                                        -- �e�|�P��
           ,NULL                                                        -- �f�|�P��
           ,NULL                                                        -- �g�|�P��
           ,NULL                                                        -- �h�|�P��
           ,NULL                                                        -- �i�|�P��
           ,NULL                                                        -- �j�|�P��
           ,NULL                                                        -- �k�|�P��
           ,NULL                                                        -- �e�|�Q��
           ,NULL                                                        -- �f�|�Q��
           ,NULL                                                        -- �g�|�Q��
           ,NULL                                                        -- �h�|�Q��
           ,NULL                                                        -- �i�|�Q��
           ,NULL                                                        -- �j�|�Q��
           ,NULL                                                        -- �k�|�Q��
           ,NULL                                                        -- �e�|�R��
           ,NULL                                                        -- �f�|�R��
           ,NULL                                                        -- �g�|�R��
           ,NULL                                                        -- �h�|�R��
           ,NULL                                                        -- �i�|�R��
           ,NULL                                                        -- �j�|�R��
           ,NULL                                                        -- �k�|�R��
           ,NULL                                                        -- �`�F�[���X�ŗL�G���A(�w�b�_�[)
           ,lt_head_tab(ln_head_cnt).orig_sys_document_ref              -- �󒍊֘A�ԍ�
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_order_qty       -- (�`�[�v)��������(�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_order_qty       -- (�`�[�v)��������(�P�[�X)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_order_qty       -- (�`�[�v)��������(�{�[��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_order_qty        -- (�`�[�v)��������(���v�A�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty    -- (�`�[�v)�o�א���(�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty    -- (�`�[�v)�o�א���(�P�[�X)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty    -- (�`�[�v)�o�א���(�{�[��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_pallet_shipping_qty  -- (�`�[�v)�o�א���(�p���b�g)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty     -- (�`�[�v)�o�א���(���v�A�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_stockout_qty    -- (�`�[�v)���i����(�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_stockout_qty    -- (�`�[�v)���i����(�P�[�X)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_stockout_qty    -- (�`�[�v)���i����(�{�[��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_stockout_qty     -- (�`�[�v)���i����(���v�A�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_qty             -- (�`�[�v)�P�[�X����
           ,lt_invoice_tab(ln_invoice_cnt).invoice_fold_container_qty   -- (�`�[�v)�I���R��(�o��)����
           ,lt_invoice_tab(ln_invoice_cnt).invoice_order_cost_amt       -- (�`�[�v)�������z(����)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_shipping_cost_amt    -- (�`�[�v)�������z(�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_stockout_cost_amt    -- (�`�[�v)�������z(���i)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_order_price_amt      -- (�`�[�v)�������z(����)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_shipping_price_amt   -- (�`�[�v)�������z(�o��)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_stockout_price_amt   -- (�`�[�v)�������z(���i)
           ,NULL                                                        -- (�����v)��������(�o��)
           ,NULL                                                        -- (�����v)��������(�P�[�X)
           ,NULL                                                        -- (�����v)��������(�{�[��)
           ,NULL                                                        -- (�����v)��������(���v�A�o��)
           ,NULL                                                        -- (�����v)�o�א���(�o��)
           ,NULL                                                        -- (�����v)�o�א���(�P�[�X)
           ,NULL                                                        -- (�����v)�o�א���(�{�[��)
           ,NULL                                                        -- (�����v)�o�א���(�p���b�g)
           ,NULL                                                        -- (�����v)�o�א���(���v�A�o��)
           ,NULL                                                        -- (�����v)���i����(�o��)
           ,NULL                                                        -- (�����v)���i����(�P�[�X)
           ,NULL                                                        -- (�����v)���i����(�{�[��)
           ,NULL                                                        -- (�����v)���i����(���v�A�o��)
           ,NULL                                                        -- (�����v)�P�[�X����
           ,NULL                                                        -- (�����v)�I���R��(�o��)����
           ,NULL                                                        -- (�����v)�������z(����)
           ,NULL                                                        -- (�����v)�������z(�o��)
           ,NULL                                                        -- (�����v)�������z(���i)
           ,NULL                                                        -- (�����v)�������z(����)
           ,NULL                                                        -- (�����v)�������z(�o��)
           ,NULL                                                        -- (�����v)�������z(���i)
           ,NULL                                                        -- �g�[�^���s��
           ,NULL                                                        -- �g�[�^���`�[����
           ,NULL                                                        -- �`�F�[���X�ŗL�G���A(�t�b�^�[)
           ,lt_head_tab(ln_head_cnt).account_number                     -- �ύX��ڋq�R�[�h
           ,cv_flag_yes                                                 -- �󒍘A�g�σt���O
           ,cv_creation_class                                           -- �쐬���敪
           ,cv_flag_no                                                  -- EDI�[�i�\�著�M�σt���O
           ,lt_head_tab(ln_head_cnt).price_list_id                      -- ���i�\�w�b�_ID
           ,ln_user_id                                                  -- �쐬��
           ,SYSDATE                                                     -- �쐬��
           ,ln_user_id                                                  -- �ŏI�X�V��
           ,SYSDATE                                                     -- �ŏI�X�V��
           ,ln_login_id                                                 -- �ŏI�X�V���O�C��
           ,NULL                                                        -- �v��ID
           ,NULL                                                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,NULL                                                        -- �R���J�����g�E�v���O����ID
           ,NULL                                                        -- �v���O�����X�V��
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_table_name := cv_tbl_name_head;
            RAISE table_insert_expt;
        END;
      END IF;  -- �w�b�_�����ΏہH
    END LOOP head_insert_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
/* 2009/08/11 Ver1.7 Add Start */
    -- *** ORG_ID�擾��O�n���h�� ***
    WHEN org_id_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/08/11 Ver1.7 Add End   */
    -- *** ����敪���ݗ�O�n���h�� ***
    WHEN sale_class_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := cv_prg_name;
--      ov_errmsg  := cv_sale_class_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod End   */
--
    -- *** OUTBOUND�ۗ�O�n���h�� ***
    WHEN outbound_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := cv_prg_name;
--      ov_errmsg  := cv_outbound_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod End   */
--
    -- *** �}����O�n���h�� ***
    WHEN table_insert_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := SUBSTRB(lv_table_name||SQLERRM,1,5000);
--
    -- *** �i�ڕϊ���O�n���h�� ***
    WHEN item_conv_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := SUBSTRB( cv_prg_name || SQLERRM, 1, 5000 );
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                       iv_application => 'XXCOS'
--                      ,iv_name        => 'APP-XXCOS-xxxxx'
--                    );
      lv_errmsg  := SUBSTRB( SQLERRM, 1, 5000);
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod Start */
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edi_manual_order_acquisition;
--
END xxcos_edi_common_pkg;
/
