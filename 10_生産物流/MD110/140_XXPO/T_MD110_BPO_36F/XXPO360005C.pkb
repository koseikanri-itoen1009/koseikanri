CREATE OR REPLACE PACKAGE BODY xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(body)
 * Description      : �d���i���[�j
 * MD.050/070       : �d���i���[�jIssue1.0  (T_MD050_BPO_360)
 *                    ��s������            (T_MD070_BPO_36F)
 * Version          : 1.25
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��܂��B(vendor_type)
 *  fnc_get_in_statement      FUNCTION  : IN��̓��e��Ԃ��܂��B(dept_code_type)
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_out_xml               PROCEDURE : XML�o�͏���
 *  prc_initialize            PROCEDURE : �O����(F-2)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(F-3-1)
 *  prc_edit_data             PROCEDURE : �擾�f�[�^�ҏW(F-3-2)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  prc_set_param             PROCEDURE : �p�����[�^�̎擾
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/04    1.0   T.Endou          �V�K�쐬
 *  2008/05/09    1.1   T.Endou          �����Ȃ��d����ԕi�f�[�^�����o����Ȃ��Ή�
 *  2008/05/13    1.2   T.Endou          OPM�i�ڏ��VIEW�Q�Ƃ��폜
 *  2008/05/13    1.3   T.Endou          �����Ȃ��d����ԕi�̂Ƃ��Ɏg�p����P�����s��
 *                                       �u�P���v����u������P���v�ɏC��
 *  2008/05/14    1.4   T.Endou          �Z�L�����e�B�v���s��Ή�
 *  2008/05/23    1.5   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/26    1.6   T.Endou          ��������d����ԕi�̏ꍇ�́A�ȉ����g�p����C��
 *                                       1.�ԕi�A�h�I��.������P��
 *                                       2.�ԕi�A�h�I��.�a������K���z
 *                                       3.�ԕi�A�h�I��.���ۋ��z
 *  2008/05/26    1.7   T.Endou          �O���q�Ƀ��[�U�[�̃Z�L�����e�B�͕s�v�Ȃ��ߍ폜
 *  2008/06/25    1.8   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/10/22    1.9   I.Higa           �����̎擾���ڂ��s���i�d���於�ː������j
 *  2008/10/24    1.10  T.Ohashi         T_S_432�Ή��i�h�̂̕t�^�j
 *  2008/11/04    1.11  Y.Yamamoto       ������Q#471
 *  2008/11/28    1.12  T.Yoshimoto      �{�ԏ�Q#204
 *  2009/01/08    1.13  N.Yoshida        �{�ԏ�Q#970
 *  2009/03/30    1.14  A.Shiina         �{�ԏ�Q#1346
 *  2009/05/26    1.15  T.Yoshimoto      �{�ԏ�Q#1478
 *  2009/06/02    1.16  T.Yoshimoto      �{�ԏ�Q#1516
 *  2009/06/22    1.17  T.Yoshimoto      �{�ԏ�Q#1516(��)��v1.15�Ή����̏�Q
 *  2009/08/10    1.18  T.Yoshimoto      �{�ԏ�Q#1596
 *  2009/09/24    1.19  T.Yoshimoto      �{�ԏ�Q#1523
 *  2012/08/16    1.20  T.Makuta         E_�{�ғ�_09898
 *  2013/07/05    1.21  R.Watanabe       E_�{�ғ�_10839
 *  2019/08/30    1.22  Y.Shoji          E_�{�ғ�_15601
 *  2019/10/18    1.23  H.Ishii          E_�{�ғ�_15601
 *  2019/11/12    1.24  H.Ishii          E_�{�ғ�_16036
 *  2023/10/10    1.25  R.Oikawa         E_�{�ғ�_19497
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XPO360005C';  -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '��s������';  -- ���[��
  gv_report_id              CONSTANT VARCHAR2(12) := 'XXPO360005T'; -- ���[ID
  gd_exec_date              CONSTANT DATE         := SYSDATE;       -- ���{��
--
  gv_org_id                 CONSTANT VARCHAR2(20) := 'ORG_ID'; -- �c�ƒP��
-- 2019/08/30 Ver1.22 Add Start
  cv_sales_org_id           CONSTANT VARCHAR2(20) := 'XXCMN_SALES_ORG_ID';   -- XXCMN:�c��ORG_ID
  cv_tax_kbn_0000           CONSTANT VARCHAR2(20) := 'XXPO_TAX_KBN_0000';    -- XXPO:�ŋ敪_�ΏۊO
  cv_max_line_9             CONSTANT VARCHAR2(20) := 'XXPO_MAX_LINE_NUMBER'; -- XXPO:�\���\���א��Z�o�p
-- 2019/08/30 Ver1.22 Add End
--
-- 2019/08/30 Ver1.22 Add Start
  cv_xxpo_tax_type          CONSTANT VARCHAR2(13) := 'XXPO_TAX_TYPE';      -- XXPO:�ŋ敪
  cv_xxpo_line_count        CONSTANT VARCHAR2(15) := 'XXPO_LINE_COUNT';    -- XXPO:���א�
-- 2019/08/30 Ver1.22 Add End
  gv_xxcmn_consumption_tax_rate CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE'; -- �����
  gv_seqrt_view             CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�Bview' ;
  gv_seqrt_view_key         CONSTANT VARCHAR2(20) := '�]�ƈ�ID' ;
-- add start 1.10
  gv_keishou                CONSTANT VARCHAR2(10) := '�a' ;
-- add end 1.10
--
  ------------------------------
  -- �Z�L�����e�B�敪
  ------------------------------
  gc_seqrt_class_vender   CONSTANT VARCHAR2(1) := '2'; -- �����i�����ҁj
  gc_seqrt_class_outside  CONSTANT VARCHAR2(1) := '4'; -- �O���q��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ; -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;  -- �A�v���P�[�V�����iXXPO�j
-- 2019/08/30 Ver1.22 Add Start
  -- ���b�Z�[�W�R�[�h
  cv_msg_po_10127         CONSTANT VARCHAR2(50) := 'APP-XXPO-10127';    -- �擾�s�G���[
  cv_msg_po_10156         CONSTANT VARCHAR2(50) := 'APP-XXPO-10156';    -- �v���t�@�C���擾�G���[
  cv_msg_po_10296         CONSTANT VARCHAR2(50) := 'APP-XXPO-10296';    -- �U������擾�G���[
--
  -- �g�[�N��
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';             -- �g�[�N���F�G���g����
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';             -- �g�[�N���F�e�[�u����
  cv_tkn_name             CONSTANT VARCHAR2(20) := 'NAME';              -- �g�[�N���F����
  cv_tkn_vendor           CONSTANT VARCHAR2(20) := 'VENDOR';            -- �g�[�N���F�����R�[�h
  cv_tkn_factory          CONSTANT VARCHAR2(20) := 'FACTORY';           -- �g�[�N���F�H��R�[�h
--
  -- �g�[�N���l
  cv_msg_out_data_01      CONSTANT VARCHAR2(30) := 'APP-XXPO-50001';    -- ��������
  cv_msg_out_data_02      CONSTANT VARCHAR2(30) := 'APP-XXPO-50002';    -- �Q�ƕ\
  cv_msg_out_data_03      CONSTANT VARCHAR2(30) := 'APP-XXPO-50003';    -- �ŋ敪����\���
  cv_msg_out_data_04      CONSTANT VARCHAR2(30) := 'APP-XXPO-50004';    -- ���א�
-- 2019/08/30 Ver1.22 Add End
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_yyyy_format     CONSTANT VARCHAR2(30) := 'YYYY' ;
  gc_char_yy_format       CONSTANT VARCHAR2(30) := 'YY' ;
  gc_char_mm_format       CONSTANT VARCHAR2(30) := 'MM' ;
  gc_char_dd_format       CONSTANT VARCHAR2(30) := 'DD' ;
  gc_char_yyyymm_format   CONSTANT VARCHAR2(30) := 'YYYY/MM' ;
--
  gv_s01                  CONSTANT VARCHAR2(3) := '/01';
  gn_zero                 CONSTANT NUMBER := 0;
  gn_one                  CONSTANT NUMBER := 1;
  gn_10                   CONSTANT NUMBER := 10;
  gn_11                   CONSTANT NUMBER := 11;
  gn_15                   CONSTANT NUMBER := 15;
  gn_16                   CONSTANT NUMBER := 16;
  gn_20                   CONSTANT NUMBER := 20;
  gn_21                   CONSTANT NUMBER := 21;
  gn_30                   CONSTANT NUMBER := 30;
-- add start 1.10
  gn_40                   CONSTANT NUMBER := 40;
-- add end 1.10
-- 2019/08/30 Ver1.22 Add Start
  gn_75                   CONSTANT NUMBER := 75;
  gn_76                   CONSTANT NUMBER := 76;
  gn_150                  CONSTANT NUMBER := 150;
-- 2019/08/30 Ver1.22 Add End
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  gv_ja                   CONSTANT VARCHAR2(2) := 'JA';
  gv_ast                  CONSTANT VARCHAR2(1) := '*';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data IS RECORD(
      deliver_from       VARCHAR2(10)   -- �[����FROM
     ,deliver_to         VARCHAR2(10)   -- �[����TO
     ,d_deliver_from     DATE           -- �[����FROM(���t�^)
     ,d_deliver_to       DATE           -- �[����TO(���t�^)
     ,vendor_code        vendor_type    -- �����P�`�T
     ,assen_vendor_code  vendor_type    -- �����҂P�`�T
     ,dept_code          dept_code_type -- �S�������P�`�T
     ,security_flg       VARCHAR2(1)    -- �Z�L�����e�B�敪
    ) ;
--
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
  -- ��s�������f�[�^�i�[�p���R�[�h�ϐ�(�ҏW�O)
  TYPE rec_data_type_dtl2  IS RECORD(
      segment1_s           xxcmn_vendors2_v.segment1%TYPE         -- �d����R�[�h
     ,segment1_a           xxcmn_vendors2_v.segment1%TYPE         -- �����҃R�[�h
     ,vendor_name          xxcmn_vendors2_v.vendor_name%TYPE      -- �d���於
     ,zip                  xxcmn_vendors2_v.zip%TYPE              -- �X�֔ԍ�
     ,address_line1        xxcmn_vendors2_v.address_line1%TYPE    -- �����Z���P
     ,address_line2        xxcmn_vendors2_v.address_line2%TYPE    -- �����Z���Q
     ,phone                xxcmn_vendors2_v.phone%TYPE            -- �����d�b
     ,fax                  xxcmn_vendors2_v.fax%TYPE              -- �����FAX
     ,vendor_full_name     xxcmn_vendors2_v.vendor_full_name%TYPE -- �����Җ��P
     ,attribute10          po_headers_all.attribute10%TYPE        -- �����R�[�h(����)
     ,quantity             xxpo_rcv_and_rtn_txns.quantity%TYPE    -- ����
     ,purchase_amount      NUMBER                                 -- �d�����z
     ,attribute5           po_line_locations_all.attribute5%TYPE  -- �a������K���z
     ,attribute8           po_line_locations_all.attribute8%TYPE  -- ���ۋ��z
     ,purchase_amount_tax  NUMBER                                 -- �d�����z(�����)
     ,attribute5_tax       po_line_locations_all.attribute5%TYPE  -- �a������K���z(�����)
     ,txns_type            xxpo_rcv_and_rtn_txns.txns_type%TYPE   -- ���ы敪
     ,kobiki_mae           po_lines_all.attribute8%TYPE           -- �P��(�����O�P��)
     ,unit_price           po_line_locations_all.attribute2%TYPE  -- �P��(������P��)
     ,kobiki_rate          po_line_locations_all.attribute1%TYPE  -- ������
     ,kousen_k             po_line_locations_all.attribute3%TYPE  -- ���K�敪
     ,kousen               po_line_locations_all.attribute4%TYPE  -- ���K
     ,fukakin_k            po_line_locations_all.attribute6%TYPE  -- ���ۋ��敪
     ,fukakin              po_line_locations_all.attribute7%TYPE  -- ���ۋ�
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
     ,tax_date             po_headers_all.attribute4%TYPE         -- ����Ŋ��
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
-- 2019/08/30 Ver1.22 Add Start
     ,factory_code         xxpo_rcv_and_rtn_txns.factory_code%TYPE -- �H��R�[�h
     ,tax                  xxcmm_item_tax_rate_v.tax%TYPE          -- �ŗ�
     ,tax_code             xxcmm_item_tax_rate_v.tax_code_ex%TYPE  -- �ŃR�[�h
     ,tax_kbn              fnd_lookup_values.description%type      -- �ŋ敪
     ,attribute3           fnd_lookup_values.attribute3%TYPE       -- �ŋ敪
-- 2019/08/30 Ver1.22 Add End
    ) ;
  TYPE tab_data_type_dtl2 IS TABLE OF rec_data_type_dtl2 INDEX BY BINARY_INTEGER ;
-- 2009/05/26 v1.15 T.Yoshimoto Add End
--
  -- ��s�������f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      segment1_s           xxcmn_vendors2_v.segment1%TYPE         -- �d����R�[�h
     ,segment1_a           xxcmn_vendors2_v.segment1%TYPE         -- �����҃R�[�h
     ,vendor_name          xxcmn_vendors2_v.vendor_name%TYPE      -- �d���於
     ,zip                  xxcmn_vendors2_v.zip%TYPE              -- �X�֔ԍ�
     ,address_line1        xxcmn_vendors2_v.address_line1%TYPE    -- �����Z���P
     ,address_line2        xxcmn_vendors2_v.address_line2%TYPE    -- �����Z���Q
     ,phone                xxcmn_vendors2_v.phone%TYPE            -- �����d�b
     ,fax                  xxcmn_vendors2_v.fax%TYPE              -- �����FAX
     ,vendor_full_name     xxcmn_vendors2_v.vendor_full_name%TYPE -- �����Җ��P
     ,attribute10          po_headers_all.attribute10%TYPE        -- �����R�[�h(����)
     ,quantity             xxpo_rcv_and_rtn_txns.quantity%TYPE    -- ����
     ,purchase_amount      NUMBER                                 -- �d�����z
     ,attribute5           po_line_locations_all.attribute5%TYPE  -- �a������K���z
     ,attribute8           po_line_locations_all.attribute8%TYPE  -- ���ۋ��z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
     ,purchase_amount_tax  NUMBER                                 -- �d�����z(�����)
     ,attribute5_tax       po_line_locations_all.attribute5%TYPE  -- �a������K���z(�����)
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
-- 2019/08/30 Ver1.22 Add Start
     ,purchase_tax_kbn      fnd_lookup_values.description%TYPE                -- �d���ŋ敪
     ,comm_price_tax_kbn    fnd_lookup_values.attribute1%TYPE                 -- ���K�ŋ敪
     ,bank_name             ap_bank_branches.bank_name%TYPE                   -- ���Z�@�֖�
     ,bank_branch_name      ap_bank_branches.bank_branch_name%TYPE            -- �x�X��
     ,bank_account_type     VARCHAR2(4)                                       -- �a���敪
     ,bank_account_num      ap_bank_accounts_all.bank_account_num%TYPE        -- ����No
     ,bank_account_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE -- �������`��
     ,break_page_flg        VARCHAR2(1)                                       -- ���y�[�W�t���O
-- 2019/08/30 Ver1.22 Add End
-- Ver1.25 Add Start
     ,invoice_t_no          VARCHAR2(14)                          -- �o�^�ԍ�
-- Ver1.25 Add End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
-- 2019/08/30 Ver1.22 Add Start
  -- �ŋ敪������
  TYPE g_description_ttype            IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY PLS_INTEGER;
  gt_description_tbl                  g_description_ttype;
  -- �ŋ敪������
  TYPE g_attribute2_ttype            IS TABLE OF fnd_lookup_values.attribute2%TYPE INDEX BY PLS_INTEGER;
  gt_attribute2_tbl                  g_attribute2_ttype;
  -- �ŋ敪
  TYPE g_tax_kbn_bd_ttype             IS TABLE OF VARCHAR2(8) INDEX BY PLS_INTEGER;
  gt_tax_kbn_bd_tab                   g_tax_kbn_bd_ttype;
  -- �ŋ敪(�ŋ敪����o�͗p)
  TYPE g_tax_kbn_bd_1_ttype           IS TABLE OF VARCHAR2(14) INDEX BY PLS_INTEGER;
  gt_tax_kbn_bd_1_tab                 g_tax_kbn_bd_1_ttype;
  -- �d�����z(�Ŕ�)
  TYPE g_p_amount_bd_ttype            IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_p_amount_bd_tab                  g_p_amount_bd_ttype;
  -- �d�������
  TYPE g_p_amount_tax_bd_ttype        IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_p_amount_tax_bd_tab              g_p_amount_tax_bd_ttype;
  -- ���K���z(�Ŕ�)
  TYPE g_unit_price_rate_bd_ttype     IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_unit_price_rate_bd_tab           g_unit_price_rate_bd_ttype;
  -- ���K�����
  TYPE g_unit_price_rate_tax_bd_ttype IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_unit_price_rate_tax_bd_tab         g_unit_price_rate_tax_bd_ttype;
  -- ���ۋ�
  TYPE g_l_unit_price_rate_bd_ttype   IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_l_unit_price_rate_bd_tab         g_l_unit_price_rate_bd_ttype;
  -- ���ۋ������
  TYPE g_l_u_price_rate_tax_bd_ttype  IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_l_u_price_rate_tax_bd_tab        g_l_u_price_rate_tax_bd_ttype;
  -- ���v(�Ŕ����z)
  TYPE g_tax_exc_amount_bd_ttype      IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_tax_exc_amount_bd_tab            g_tax_exc_amount_bd_ttype;
  -- ���v(�����)
  TYPE g_ded_amount_tax_bd_ttype      IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_ded_amount_tax_bd_tab            g_ded_amount_tax_bd_ttype;
-- 2019/08/30 Ver1.22 Add End
-- Ver1.25 Add Start
  TYPE g_tax_rate_ttype               IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_tax_rate_tab                     g_tax_rate_ttype;
  TYPE g_kousen_tax_rate_ttype        IS TABLE OF NUMBER  INDEX BY PLS_INTEGER;
  gt_kousen_tax_rate_tab              g_kousen_tax_rate_ttype;
-- Ver1.25 Add End
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
--  
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;        -- �c�ƒP�ʁi���Y�j
-- 2019/08/30 Ver1.22 Add Start
  gn_sales_org_id           po_vendor_sites_all.org_id%TYPE ;             -- �c�ƒP�ʁi�c�Ɓj
-- 2019/08/30 Ver1.22 Add End
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- �S����
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;      -- �d����R�[�h
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;      -- �d����T�C�g�R�[�h
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                    -- �d����ID
--
  gn_tax                    NUMBER; -- ����ŌW��
-- 2019/08/30 Ver1.22 Add Start
--
  gv_tax_kbn_0000           VARCHAR2(20);     -- XXPO:�ŋ敪_�ΏۊO
--
  gn_tax_kbn                NUMBER DEFAULT 0; -- �ŋ敪����\�J�E���g
  gn_line_count             NUMBER DEFAULT 0; -- �\���\���א�
  gn_max_line_9             NUMBER DEFAULT 0; -- �\���\���א��Z�o�p
--
  gv_break_page_flg         VARCHAR2(60);     -- �ŏI�d����̒��[���y�[�W�t���O
  gv_from_dept_name         VARCHAR2(60);     -- �����於
  gv_from_postal_code       VARCHAR2(8);      -- �X�֔ԍ�
  gv_from_address           VARCHAR2(60);     -- �Z��

-- 2019/08/30 Ver1.22 Add End
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(vendor_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_vendor_type IN vendor_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vendor_code_loop>>
    FOR ln_cnt IN 1..itbl_vendor_type.COUNT LOOP
      lv_in := lv_in || '''' || itbl_vendor_type(ln_cnt) || ''',';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(dept_code_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_dept_code_type IN dept_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<dept_code_type_loop>>
    FOR ln_cnt IN 1..itbl_dept_code_type.COUNT LOOP
      lv_in := lv_in || '''' || itbl_dept_code_type(ln_cnt) || ''',';
    END LOOP dept_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml
   * Description      : XML�o�͏���
   ***********************************************************************************/
  PROCEDURE prc_out_xml(
      ov_errbuf         OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param          IN  rec_param_data -- ���̓p�����[�^�Q
     ,it_xml_data_table IN  XML_DATA       -- �擾���R�[�h�Q
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_xml_string        VARCHAR2(32000);
--
    -- *** ���[�J���E��O���� ***
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- �w�l�k�w�b�_�[�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- �w�l�k�f�[�^���o��
    <<xml_data_table>>
    FOR i IN 1 .. it_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := fnc_conv_xml(
                          iv_name   => it_xml_data_table(i).tag_name    -- �^�O�l�[��
                         ,iv_value  => it_xml_data_table(i).tag_value   -- �^�O�f�[�^
                         ,ic_type   => it_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- �w�l�k�t�b�_�[�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_out_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(F-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param      IN     rec_param_data   -- ���̓p�����[�^�Q
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
-- 2019/08/30 Ver1.22 Add Start
    -- *** ���[�J���E�萔 ***
    cv_xxpo_billing_information CONSTANT VARCHAR2(24) := 'XXPO_BILLING_INFORMATION'; -- XXPO�F��������
--
-- 2019/08/30 Ver1.22 Add End
    -- *** ���[�J���ϐ� ***
-- 2019/08/30 Ver1.22 Add Start
    lt_lookup_code    fnd_lookup_values.lookup_code%TYPE;
-- 2019/08/30 Ver1.22 Add End
--
    -- *** ���[�J���E��O���� ***
    get_value_expt    EXCEPTION ;     -- �l�擾�G���[
-- 2013/07/05 v1.21 R.Watanabe Del Start E_�{�ғ�_10839
--    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- �����
-- 2013/07/05 v1.21 R.Watanabe Del End E_�{�ғ�_10839
    ld_deliver_from   DATE; -- �[����FROM�̔N����1��
--
-- 2019/08/30 Ver1.22 Add Start
    -- *** ���[�J���E�J�[�\�� ***
    -- �ŋ敪������
    CURSOR  tax_kbn_cur
    IS
--      SELECT xlv2.description AS description  -- �ŋ敪
      SELECT xlv2.description AS description  -- �ŋ敪
            ,xlv2.attribute2  AS attribute2   -- �ŋ敪_�ŋ敪����o�͗p
      FROM   xxcmn_lookup_values2_v xlv2
      WHERE  xlv2.lookup_type = cv_xxpo_tax_type
      AND    FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
                              BETWEEN xlv2.start_date_active
                              AND     NVL(xlv2.end_date_active ,FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format ))
      ORDER BY xlv2.attribute1
      ;
--
-- 2019/08/30 Ver1.22 Add End
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( gv_org_id ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005' ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
-- 2019/08/30 Ver1.22 Add Start
    -- ====================================================
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_org_id := FND_PROFILE.VALUE( cv_sales_org_id ) ;
    IF ( gn_sales_org_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10156
                                            ,cv_tkn_name
                                            ,cv_sales_org_id ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �ŋ敪_�ΏۊO�擾
    -- ====================================================
    gv_tax_kbn_0000 := FND_PROFILE.VALUE( cv_tax_kbn_0000 ) ;
    IF ( gv_tax_kbn_0000 IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10156
                                            ,cv_tkn_name
                                            ,cv_tax_kbn_0000 ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �\���\���א��Z�o�p�擾
    -- ====================================================
    gn_max_line_9 := FND_PROFILE.VALUE( cv_max_line_9 ) ;
    IF ( gn_max_line_9 IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10156
                                            ,cv_tkn_name
                                            ,cv_max_line_9 ) ;
      lv_retcode := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
-- 2019/08/30 Ver1.22 Add End
-- 2013/07/05 v1.21 R.Watanabe Del Start E_�{�ғ�_10839
/*
    -- ====================================================
    -- ����Ŏ擾
    -- ====================================================
    -- �[����FROM�̔N����1��
    ld_deliver_from := FND_DATE.STRING_TO_DATE(
      (TO_CHAR(ir_param.d_deliver_from,gc_char_yyyymm_format) || gv_s01),gc_char_dt_format);
    BEGIN
      SELECT
        flv.lookup_code
      INTO
        lv_tax
      FROM
        xxcmn_lookup_values2_v flv
      WHERE
            flv.lookup_type = gv_xxcmn_consumption_tax_rate
        AND ((flv.start_date_active <= ld_deliver_from)
          OR (flv.start_date_active IS NULL))
        AND ((flv.end_date_active   >= ld_deliver_from)
          OR (flv.end_date_active   IS NULL));
      -- ����ŌW��
      gn_tax := TO_NUMBER(lv_tax) / 100;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gc_application_po
                      ,'APP-XXPO-00006');
        lv_retcode  := gv_status_error ;
        RAISE get_value_expt ;
    END;
*/
-- 2013/07/05 v1.21 R.Watanabe Del End E_�{�ғ�_10839
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- �d����R�[�h�E�d����T�C�g�R�[�h�擾
    -- ====================================================
    BEGIN
--
      SELECT xssv.vendor_code
            ,xssv.vendor_site_code
            ,vnd.vendor_id
      INTO   gv_user_vender
            ,gv_user_vender_site
            ,gn_user_vender_id
      FROM  xxpo_security_supply_v xssv
           ,xxcmn_vendors2_v       vnd
      WHERE xssv.vendor_code    = vnd.segment1 (+)
      AND   xssv.user_id        = gn_user_id
      AND   xssv.security_class = ir_param.security_flg
      AND   FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
            BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
--
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
--
-- 2019/08/30 Ver1.22 Add Start
    -- ====================================================
    -- ��������̎擾
    -- ====================================================
    BEGIN
--
      SELECT flv.attribute1  from_dept_name    -- �����於
            ,flv.attribute2  from_postal_code  -- �X�֔ԍ�
            ,flv.attribute3  from_address      -- �Z��
      INTO   gv_from_dept_name
            ,gv_from_postal_code
            ,gv_from_address
      FROM   xxcmn_lookup_values2_v flv
      WHERE  flv.lookup_type = cv_xxpo_billing_information
      AND    FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
             BETWEEN flv.start_date_active
             AND     NVL(flv.end_date_active ,FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format ))
      ;
--
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                              ,cv_msg_po_10127
                                              ,cv_tkn_entry
                                              ,cv_msg_out_data_01
                                              ,cv_tkn_table
                                              ,cv_msg_out_data_02 ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
--
    -- ====================================================
    -- �ŋ敪����\���̎擾
    -- ====================================================
    -- �I�[�v��
    OPEN tax_kbn_cur;
    -- �o���N�t�F�b�`
    FETCH tax_kbn_cur BULK COLLECT INTO gt_description_tbl,gt_attribute2_tbl;
    -- �J�[�\���N���[�Y
    CLOSE tax_kbn_cur;
--
    -- �擾�f�[�^���O���̏ꍇ
    IF ( gt_description_tbl.COUNT = 0 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,cv_msg_po_10127
                                            ,cv_tkn_entry
                                            ,cv_msg_out_data_03
                                            ,cv_tkn_table
                                            ,cv_msg_out_data_02 ) ;
      lv_retcode  := gv_status_error ;
      RAISE get_value_expt ;
    END IF;
--
    lt_lookup_code := TO_CHAR(gt_description_tbl.count);
--
    -- �ŋ敪�ɑ΂��āA1�y�[�W�ɕ\���\�Ȗ��א����擾
    BEGIN
      SELECT TO_NUMBER(xlv2.description) AS line_count  -- ���א�
      INTO   gn_line_count
      FROM   xxcmn_lookup_values2_v xlv2
      WHERE  xlv2.lookup_type = cv_xxpo_line_count
      AND    xlv2.lookup_code = lt_lookup_code
      AND    FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format )
                              BETWEEN xlv2.start_date_active
                              AND     NVL(xlv2.end_date_active ,FND_DATE.STRING_TO_DATE( ir_param.deliver_from, gc_char_d_format ))
      ORDER BY xlv2.attribute1
      ;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                              ,cv_msg_po_10127
                                              ,cv_tkn_entry
                                              ,cv_msg_out_data_04
                                              ,cv_tkn_table
                                              ,cv_msg_out_data_02 ) ;
        lv_retcode := gv_status_error;
        RAISE get_value_expt ;
    END;
-- 2019/08/30 Ver1.22 Add End
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(F-3-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ov_errbuf     OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param      IN  rec_param_data            -- ���̓p�����[�^�Q
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
--     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- �擾���R�[�h�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl2  -- �擾���R�[�h�Q
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_item_class       CONSTANT VARCHAR2( 1) := '5';        -- �i�ڋ敪(���i)
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';        -- ����t���O(���)
    cv_poh_approved     CONSTANT VARCHAR2(10) := 'APPROVED'; -- �����X�e�[�^�X(���F�ς�)
--
    cv_poh_decision     CONSTANT VARCHAR2( 2) := '35';       -- ������޵ݽð��(���z�m��)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';       -- ������޵ݽð��(���)
--
    cv_txn_type_acc     CONSTANT VARCHAR2( 1) := '1';-- ���ы敪:XXPO_TXNS_TYPE(���)
    cv_txn_type_rtn     CONSTANT VARCHAR2( 1) := '2';-- ���ы敪:XXPO_TXNS_TYPE(�d����ԕi)
    cv_txn_type_rtn_3   CONSTANT VARCHAR2( 1) := '3';-- ���ы敪:XXPO_TXNS_TYPE(�����Ȃ��d����ԕi)
--
    -- *** ���[�J���E�ϐ� ***
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_in         VARCHAR2(1000) ;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;  -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    lv_sql :=
         ' SELECT'
-- 2019/08/30 Ver1.22 Add Start
      || '   /*+ push_pred(xitrv) */ '
-- 2019/08/30 Ver1.22 Add End
      || '   xvv_s.segment1            AS segment1_s          ' -- �d����ԍ�
      || '  ,xvv_a.segment1            AS segment1_a          ' -- �����҃R�[�h
      || '  ,xvv_s.vendor_full_name    AS vendor_name         ' -- �d���於
      || '  ,xvv_s.zip                 AS zip                 ' -- �X�֔ԍ�
      || '  ,xvv_s.address_line1       AS address_line1       ' -- �����Z���P
      || '  ,xvv_s.address_line2       AS address_line2       ' -- �����Z���Q
      || '  ,xvv_s.phone               AS phone               ' -- �����d�b
      || '  ,xvv_s.fax                 AS fax                 ' -- �����FAX
      || '  ,xvv_a.vendor_full_name    AS vendor_full_name    ' -- �����Җ��P
      || '  ,comm.attribute10          AS attribute10         ' -- �����R�[�h(����)
      || '  ,comm.quantity             AS quantity            ' -- ����
      || '  ,comm.purchase_amount      AS purchase_amount     ' -- �d�����z
      || '  ,comm.attribute5           AS attribute5          ' -- �a������K���z
      || '  ,comm.attribute8           AS attribute8          ' -- ���ۋ��z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
      || '  ,comm.purchase_amount_tax  AS purchase_amount_tax ' -- �d�����z(�����)
      || '  ,comm.attribute5_tax       AS attribute5_tax      ' -- �a������K���z(�����)
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '  ,comm.txns_type            AS txns_type           ' -- ���ы敪
      || '  ,comm.kobiki_mae           AS kobiki_mae          ' -- �P��(�����O�P��)
      || '  ,comm.unit_price           AS unit_price          ' -- ������P��
      || '  ,comm.kobiki_rate          AS kobiki_rate         ' -- ������
      || '  ,comm.kousen_k             AS kousen_k            ' -- ���K�敪
      || '  ,comm.kousen               AS kousen              ' -- ���K
      || '  ,comm.fukakin_k            AS fukakin_k           ' -- ���ۋ��敪
      || '  ,comm.fukakin              AS fukakin             ' -- ���ۋ�
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
      || '  ,comm.tax_date              AS tax_date             ' -- ����Ŋ��
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
-- 2019/08/30 Ver1.22 Add Start
      || '  ,comm.factory_code          AS factory_code         ' -- �H��R�[�h
      || '  ,TO_NUMBER(xitrv.tax) / 100 AS tax                  ' -- �ŗ�
      || '  ,xitrv.tax_code_ex          AS tax_code             ' -- �ŃR�[�h
      || '  ,xlv2.description           AS tax_kbn              ' -- �ŋ敪
      || '  ,xlv2.attribute3            AS attribute3           ' -- �ŋ敪_�o�͗p
-- 2019/08/30 Ver1.22 Add End
      || ' FROM'
      || '   ('
      || '    SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '      com.txns_type     AS txns_type '                -- ���ы敪
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '     ,com.vendor_id     AS vendor_id'
      || '     ,com.attribute3    AS attribute3'
      || '     ,com.attribute10   AS attribute10'
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
/*
      || '     ,SUM(com.sum_quantity) AS quantity'
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
--      || '     ,SUM(NVL(com.sum_quantity,0) * com.unit_price) AS purchase_amount'
      || '     ,SUM(ROUND(NVL(com.sum_quantity,0) * com.unit_price)) AS purchase_amount'
      || '     ,SUM(com.attribute5) AS attribute5'
      || '     ,SUM(ROUND(ROUND(NVL(com.sum_quantity,0) * com.unit_price ) * ' || gn_tax || ')) AS purchase_amount_tax'
      || '     ,SUM(ROUND(com.attribute5 * ' || gn_tax || ')) AS attribute5_tax'
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
      || '     ,SUM(com.attribute8) AS attribute8'
*/
      || '      ,com.sum_quantity AS quantity '
      || '      ,ROUND(NVL(com.sum_quantity,0) * com.unit_price) AS purchase_amount '
      || '      ,com.attribute5 AS attribute5 '
-- 2013/07/05 v1.21 R.Watanabe Mod Start E_�{�ғ�_10839
--      || '      ,ROUND(ROUND(NVL(com.sum_quantity,0) * com.unit_price ) * .05) AS purchase_amount_tax '
--      || '      ,ROUND(com.attribute5 * .05) AS attribute5_tax '
       || '      ,ROUND(NVL(com.sum_quantity,0) * com.unit_price ) AS purchase_amount_tax '
       || '      ,ROUND(com.attribute5) AS attribute5_tax '
-- 2013/07/05 v1.21 R.Watanabe Mod End E_�{�ғ�_10839
      || '      ,com.attribute8              AS attribute8 '
      || '      ,com.kobiki_mae              AS kobiki_mae '     -- �P��(�����O�P��)  -- Add T.Yoshimoto
      || '      ,com.unit_price              AS unit_price '     -- ������P��        -- Add T.Yoshimoto
      || '      ,com.kobiki_rate             AS kobiki_rate '    -- ������            -- Add T.Yoshimoto
      || '      ,com.kousen_k                AS kousen_k '       -- ���K�敪          -- Add T.Yoshimoto
      || '      ,com.kousen                  AS kousen '         -- ���K              -- Add T.Yoshimoto
      || '      ,com.fukakin_k               AS fukakin_k '      -- ���ۋ��敪        -- Add T.Yoshimoto
      || '      ,com.fukakin                 AS fukakin '        -- ���ۋ�            -- Add T.Yoshimoto
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
      || '      ,com.tax_date              AS tax_date '          -- ����Ŋ��
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
-- 2019/08/30 Ver1.22 Add Start
      || '       ,com.factory_code           AS factory_code '   -- �H��R�[�h
      || '       ,com.item_id                AS item_id '        -- �i��ID
-- 2019/08/30 Ver1.22 Add End
      || '   FROM'
      || '     ('
                --�������
      || '      SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        xrart2.txns_type AS txns_type ' -- ���ы敪
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,poh.vendor_id   AS vendor_id '  -- �d����ԍ�(�����)
      || '       ,poh.attribute3  AS attribute3'  -- �d����ԍ�(������)
      || '       ,poh.attribute10 AS attribute10' -- �����R�[�h
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
/*
-- 2008/11/28 v1.12 T.Yoshimoto Mod Start �{��#204
--      || '       ,pla.unit_price  AS unit_price'  -- �P��(������P��)
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute2,0)) AS unit_price'  -- �P��(������P��)
      || '         FROM   po_line_locations_all plla' -- �����[������
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS unit_price'
-- 2008/11/28 v1.12 T.Yoshimoto Mod End �{��#204
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute5,0)) AS attribute5'-- �a������K���z
      || '         FROM   po_line_locations_all plla' -- �����[������
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS attribute5'
      || '       ,('
      || '         SELECT SUM(NVL(plla.attribute8,0)) AS attribute8'-- ���ۋ��z
      || '         FROM   po_line_locations_all plla' -- �����[������
      || '         WHERE  plla.po_line_id = pla.po_line_id'
      || '        ) AS attribute8'
      || '       ,xrart.sum_quantity AS sum_quantity'; -- ����ԕi
*/
      || '       ,TO_NUMBER(NVL(pla.attribute8,0))  AS kobiki_mae '   -- �P��(�����O�P��)
      || '       ,TO_NUMBER(NVL(plla.attribute2,0)) AS unit_price '   -- �P��(������P��)
      || '       ,TO_NUMBER(NVL(plla.attribute5,0)) AS attribute5 '   -- �a������K���z
      || '       ,TO_NUMBER(NVL(plla.attribute8,0)) AS attribute8 '   -- ���ۋ��z
      || '       ,NVL(plla.ATTRIBUTE1,0)            AS kobiki_rate '  -- ������
      || '       ,NVL(plla.ATTRIBUTE3,3)            AS kousen_k '     -- ���K�敪
      || '       ,NVL(plla.ATTRIBUTE4,0)            AS kousen '       -- ���K
      || '       ,NVL(plla.ATTRIBUTE6,3)            AS fukakin_k '    -- ���ۋ��敪
      || '       ,NVL(plla.ATTRIBUTE7,0)            AS fukakin '      -- ���ۋ�
      || '       ,xrart2.quantity                   AS sum_quantity ' -- ����ԕi
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
      || '       ,poh.attribute4                    AS tax_date '     -- �[����
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
-- 2019/08/30 Ver1.22 Add Start
      || '       ,pla.attribute2                    AS factory_code ' -- �H��R�[�h
      || '       ,xrart2.item_id                    AS item_id '      -- �i��ID
-- 2019/08/30 Ver1.22 Add End
      ;
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '      FROM'
      || '        po_headers_all        poh'   -- �����w�b�_
      || '       ,po_lines_all          pla'   -- ��������
      || '       ,xxpo_headers_all      xha'   -- �����w�b�_�i�A�h�I���j
      || '       ,xxcmn_locations2_v    xlv'   -- ���Ə����VIEW2
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,po_line_locations_all plla'   -- �����[������
      || '       ,xxpo_rcv_and_rtn_txns xrart2' -- ����ԕi����(�A�h�I��)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '      ,('
      || '        SELECT'
      || '          xrart.source_document_number   AS source_document_number'
      || '         ,xrart.source_document_line_num AS source_document_line_num'
      || '         ,MAX(xrart.txns_date)           AS txns_date'
-- 2009/05/26 v1.15 T.Yoshimoto Del Start
--      || '         ,SUM(xrart.quantity)            AS sum_quantity'
-- 2009/05/26 v1.15 T.Yoshimoto Del End
      || '        FROM'
      || '          xxpo_rcv_and_rtn_txns xrart' -- ����ԕi����(�A�h�I��)
      || '        WHERE'
      || '          xrart.txns_type = ''' || cv_txn_type_acc || '''' -- ���
      || '        GROUP BY'
      || '          xrart.source_document_number'
      || '         ,xrart.source_document_line_num'
      || '       ) xrart';
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '      WHERE'
           -- �����w�b�_
      || '            poh.org_id        = ''' || gn_sales_class || ''''
      || '        AND poh.segment1      = xha.po_header_number'
      || '        AND poh.po_header_id  = pla.po_header_id'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        AND plla.po_line_id = pla.po_line_id '
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2009/09/24 v1.19 T.Yoshimoto Del Start �{��#1523
      --|| '        AND poh.authorization_status =  ''' || cv_poh_approved || ''''
-- 2009/09/24 v1.19 T.Yoshimoto Del End �{��#1523
      || '        AND poh.attribute1           >= ''' || cv_poh_decision || '''' -- ���z�m��
      || '        AND poh.attribute1           <  ''' || cv_poh_cancel   || '''' -- ���
      || '        AND ( '
      || '             (pla.cancel_flag = ''' || gv_n || ''') '
      || '          OR (pla.cancel_flag IS NULL) '     -- �L�����Z���t���O
      || '            ) '
-- 2009/03/30 v1.14 ADD START
      || '        AND poh.org_id        = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.14 ADD END
           -- ����ԕi���уA�h�I��
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        AND xrart2.txns_type = ''' || cv_txn_type_acc || ''''
      || '        AND xrart2.source_document_number   = poh.segment1'
      || '        AND xrart2.source_document_line_num = pla.line_num'
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '        AND xrart.source_document_number   = poh.segment1'
      || '        AND xrart.source_document_line_num = pla.line_num'
      || '        AND xrart.txns_date '
      || '          BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                        || gc_char_d_format || ''')'
      || '            AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                      || gc_char_d_format || ''')';
--
    -- �p�����[�^�S������
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_sql := lv_sql
        || '        AND poh.attribute10 = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '        AND poh.attribute10  IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- ����
      || '        AND xlv.start_date_active <= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '        AND ((xlv.end_date_active >= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                || gc_char_d_format || '''))'
      || '          OR (xlv.end_date_active IS NULL)) '
      || '        AND poh.attribute10 = xlv.location_code ';
--
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || '        AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
        || '          OR ( poh.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || '        AND  NOT EXISTS(SELECT po_line_id '
          || '                        FROM   po_lines_all pl_sub '
          || '                        WHERE  pl_sub.po_header_id = poh.po_header_id '
          || '                        AND  NVL(pl_sub.attribute2,''' || gv_ast || ''') '
          || '                          <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
-- ��������d����ԕi
    lv_sql := lv_sql
      || '      UNION ALL'
      || '      SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        xrart.txns_type    AS txns_type '    -- ���ы敪
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,poh.vendor_id      AS vendor_id '    -- �d����ԍ�(�����)
      || '       ,poh.attribute3     AS attribute3'    -- �d����ԍ�(������)
      || '       ,poh.attribute10    AS attribute10'   -- �����R�[�h
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,xrart.kobiki_mae   AS kobiki_mae'    -- �P��(�����O�P��)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,xrart.unit_price   AS unit_price'    -- �P��(������P��)
      || '       ,xrart.attribute5   AS attribute5'    -- �a������K���z
      || '       ,xrart.attribute8   AS attribute8'    -- ���ۋ��z
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,NULL               AS kobiki_rate '  -- ������
      || '       ,NULL               AS kousen_k '     -- ���K�敪
      || '       ,NULL               AS kousen '       -- ���K
      || '       ,NULL               AS fukakin_k '    -- ���ۋ��敪
      || '       ,NULL               AS fukakin '      -- ���ۋ�
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
     -- || '       ,xrart.sum_quantity AS sum_quantity'; -- ����ԕi
      || '       ,xrart.sum_quantity AS sum_quantity'  -- ����ԕi
      || '       ,poh.attribute4     AS tax_date '     -- �ԕi�������[����
-- 2019/08/30 Ver1.22 Add Start
      || '       ,pla.attribute2     AS factory_code ' -- �H��R�[�h
      || '       ,xrart.item_id      AS item_id '      -- �i��ID
-- 2019/08/30 Ver1.22 Add End
      ;
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '      FROM'
      || '        po_headers_all        poh'   -- �����w�b�_
      || '       ,po_lines_all          pla'   -- ��������
      || '       ,xxpo_headers_all      xha'   -- �����w�b�_�i�A�h�I���j
      || '       ,xxcmn_locations2_v    xlv'   -- ���Ə����VIEW2
      || '       ,('
      || '         SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '          xrart.txns_type                 AS txns_type '       -- ���ы敪
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '         ,xrart.source_document_number    AS source_document_number'
      || '         ,xrart.source_document_line_num  AS source_document_line_num'
      || '         ,MAX(xrart.txns_date)            AS txns_date'
      || '         ,SUM(xrart.quantity * -1)        AS sum_quantity'     -- �}�C�i�X
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '         ,NULL                            AS kobiki_mae'       -- �P��(�����O�P��)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '         ,AVG(xrart.kobki_converted_unit_price) AS unit_price' -- ������P��
      || '         ,SUM(xrart.kousen_price * -1)    AS attribute5'       -- �a������K���z
      || '         ,SUM(xrart.fukakin_price * -1)   AS attribute8'       -- ���ۋ��z
-- 2019/08/30 Ver1.22 Add Start
      || '         ,xrart.item_id                   AS item_id'          -- �i��ID
-- 2019/08/30 Ver1.22 Add End
      || '         FROM'
      || '           xxpo_rcv_and_rtn_txns xrart' -- ����ԕi����(�A�h�I��)
      || '         WHERE'
      || '               xrart.txns_type  = ''' || cv_txn_type_rtn || '''' -- �d����ԕi
      || '           AND xrart.txns_date '
      || '             BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                           || gc_char_d_format || ''')'
      || '           AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                 || gc_char_d_format || ''')'
      || '           AND xrart.quantity > ' || gn_zero || ''
      || '         GROUP BY'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '           xrart.txns_type '               -- ���ы敪
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '          ,xrart.source_document_number'
      || '          ,xrart.source_document_line_num'
-- 2019/08/30 Ver1.22 Add Start
      || '          ,xrart.item_id'
-- 2019/08/30 Ver1.22 Add End
      || '        ) xrart';
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '      WHERE'
           -- �����w�b�_
      || '            poh.org_id        = ''' || gn_sales_class || ''''
      || '        AND poh.segment1      = xha.po_header_number'
      || '        AND poh.po_header_id  = pla.po_header_id'
-- 2009/09/24 v1.19 T.Yoshimoto Del Start �{��#1523
      --|| '        AND poh.authorization_status =  ''' || cv_poh_approved || ''''
-- 2009/09/24 v1.19 T.Yoshimoto Del End �{��#1523
      || '        AND poh.attribute1           >= ''' || cv_poh_decision || '''' -- ���z�m��
      || '        AND poh.attribute1           <  ''' || cv_poh_cancel   || '''' -- ���
      || '        AND ( '
      || '             (pla.cancel_flag = ''' || gv_n || ''') '
      || '          OR (pla.cancel_flag IS NULL) '     -- �L�����Z���t���O
      || '            ) '
-- 2009/03/30 v1.14 ADD START
      || '        AND poh.org_id        = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.14 ADD END
           -- ����ԕi���уA�h�I��
      || '        AND xrart.source_document_number   = poh.segment1'
      || '        AND xrart.source_document_line_num = pla.line_num'
      || '        AND xrart.txns_date '
      || '          BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                        || gc_char_d_format || ''')'
      || '            AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                      || gc_char_d_format || ''')';
--
    -- �p�����[�^�S������
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_sql := lv_sql
        || '        AND poh.attribute10 = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '        AND poh.attribute10  IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- ����
      || '        AND xlv.start_date_active <= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '        AND ((xlv.end_date_active >= '
      || '          FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                                || gc_char_d_format || '''))'
      || '          OR (xlv.end_date_active IS NULL)) '
      || '        AND poh.attribute10 = xlv.location_code ';
--
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || '        AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
        || '          OR ( poh.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || '        AND  NOT EXISTS(SELECT po_line_id '
          || '                        FROM   po_lines_all pl_sub '
          || '                        WHERE  pl_sub.po_header_id = poh.po_header_id '
          || '                        AND  NVL(pl_sub.attribute2,''' || gv_ast || ''') '
          || '                          <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
-- �����Ȃ��d����ԕi
    lv_sql :=  lv_sql
      || ' UNION ALL'
      || '      SELECT'
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '        xrart.txns_type                    AS txns_type '    -- ���ы敪
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,xrart.vendor_id                    AS vendor_id '  -- �d����ԍ�(�����)
      || '       ,TO_CHAR(xrart.assen_vendor_id)     AS attribute3'  -- �d����ԍ�(������)
      || '       ,xrart.department_code              AS attribute10' -- �����R�[�h
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,NULL                               AS kobiki_mae'    -- �P��(�����O�P��)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
      || '       ,xrart.kobki_converted_unit_price   AS unit_price'  -- �P��
      || '       ,xrart.kousen_price * -1            AS attribute5'  -- �a������K���z
      || '       ,xrart.fukakin_price * -1           AS attribute8'  -- ���ۋ��z
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      || '       ,NULL                               AS kobiki_rate '  -- ������
      || '       ,NULL                               AS kousen_k '     -- ���K�敪
      || '       ,NULL                               AS kousen '       -- ���K
      || '       ,NULL                               AS fukakin_k '    -- ���ۋ��敪
      || '       ,NULL                               AS fukakin '      -- ���ۋ�
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
     -- || '       ,xrart.quantity * -1                AS sum_quantity'; -- ����
      || '       ,xrart.quantity * -1                AS sum_quantity'  -- ����
      || '       ,TO_CHAR(xrart.txns_date,''YYYY/MM/DD'')     AS tax_date '    -- �����
-- 2019/08/30 Ver1.22 Add Start
      || '       ,xrart.factory_code                 AS factory_code ' -- �H��R�[�h
      || '       ,xrart.item_id                      AS item_id '      -- �i��ID
-- 2019/08/30 Ver1.22 Add End
      ;
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_sql :=  lv_sql
      || '   FROM '
      || '     xxpo_rcv_and_rtn_txns xrart'  -- ����ԕi����(�A�h�I��)
      || '    ,xxcmn_locations2_v    xlv ';  -- ���Ə����VIEW2
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || '   WHERE '
      || '         xrart.txns_type = ''' || cv_txn_type_rtn_3 || '''' -- �����Ȃ��d����ԕi
      || '     AND xrart.quantity  > ' || gn_zero || ''
      || '     AND xrart.txns_date'
      || '           BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                         || gc_char_d_format || ''')'
      || '     AND FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                               || gc_char_d_format || ''')';
--
    -- �p�����[�^�S������
    IF (ir_param.dept_code.COUNT = gn_one) THEN
      -- 1���̂�
      lv_sql := lv_sql
        || '     AND xrart.department_code = ''' || ir_param.dept_code(gn_one) || '''';
    ELSIF (ir_param.dept_code.COUNT > gn_one) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_param.dept_code);
      lv_sql := lv_sql
        || '     AND xrart.department_code IN(' || lv_in || ')';
    END IF;
--
    lv_sql :=  lv_sql
           -- ����
      || '     AND xlv.start_date_active <= '
      || '       FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                             || gc_char_d_format || ''')'
      || '     AND ((xlv.end_date_active >= '
      || '       FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                             || gc_char_d_format || '''))'
      || '       OR (xlv.end_date_active IS NULL)) '
      || '     AND xrart.department_code = xlv.location_code ';
--
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_flg = gc_seqrt_class_vender) THEN
      lv_sql := lv_sql
        || ' AND (   ( xrart.assen_vendor_id = ''' || gn_user_vender_id || ''')'
        || '      OR ( xrart.vendor_id  = ' || NVL(gn_user_vender_id,0) || '))'
        ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_sql := lv_sql
          || ' AND  NOT EXISTS(SELECT xrart_sub.factory_code '
          || '                 FROM   xxpo_rcv_and_rtn_txns xrart_sub '
          || '                 WHERE  xrart_sub.rcv_rtn_number = xrart.rcv_rtn_number '
          || '                   AND  NVL(xrart_sub.factory_code,''' || gv_ast || ''') '
          || '                        <> '''|| gv_user_vender_site ||''')'
          ;
      END IF;
    END IF;
--
    lv_sql := lv_sql
      || '     ) com '
-- 2009/05/26 v1.15 T.Yoshimoto Del Start
--      || '   GROUP BY '
--      || '     com.vendor_id '
--      || '    ,com.attribute3 '
--      || '    ,com.attribute10 '
-- 2009/05/26 v1.15 T.Yoshimoto Del End
      || '   ) comm '
      || '  ,xxcmn_vendors2_v xvv_s ' -- �d������VIEW2 �����
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
/*
      || '  ,('
      || '    SELECT'
      || '      xvv_a.vendor_id        AS vendor_id'
      || '     ,xvv_a.segment1         AS segment1'
      || '     ,xvv_a.vendor_full_name AS vendor_full_name'
      || '    FROM xxcmn_vendors2_v xvv_a'
      || '    WHERE'
      || '      xvv_a.start_date_active <= '
      || '        FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '    AND ((xvv_a.end_date_active >= '
      || '      FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                            || gc_char_d_format || '''))'
      || '      OR (xvv_a.end_date_active IS NULL)) '
      || '   ) xvv_a' -- �d������VIEW2 ����
*/
      || '  ,xxcmn_vendors2_v xvv_a '
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
-- 2019/08/30 Ver1.22 Add Start
      || '  ,xxcmm_item_tax_rate_v  xitrv '
      || '  ,xxcmn_lookup_values2_v xlv2 '
-- 2019/08/30 Ver1.22 Add End
      || ' WHERE '
      -- ������
      || '   xvv_a.vendor_id(+) = comm.attribute3 '
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
      || '   AND NVL(xvv_a.start_date_active, FND_DATE.STRING_TO_DATE(''1900/01/01'',''YYYY/MM/DD'')) <= '
      || '        FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                                || gc_char_d_format || ''')'
      || '   AND ((NVL(xvv_a.end_date_active, FND_DATE.STRING_TO_DATE(''9999/12/31'',''YYYY/MM/DD'')) >= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                            || gc_char_d_format || '''))'
      || '      OR (xvv_a.end_date_active IS NULL)) '
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
      -- �����
      || '   AND xvv_s.start_date_active <= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_from || ''','''
                                           || gc_char_d_format || ''')'
      || '   AND ((xvv_s.end_date_active >= '
      || '     FND_DATE.STRING_TO_DATE(''' || ir_param.deliver_to || ''','''
                                           || gc_char_d_format || '''))'
      || '     OR (xvv_s.end_date_active IS NULL)) '
-- 2019/08/30 Ver1.22 Mod Start
--      || '   AND xvv_s.vendor_id = comm.vendor_id ';
      || '   AND xvv_s.vendor_id = comm.vendor_id '
      -- �ŗ�
      || '   AND comm.item_id  =  xitrv.item_id '
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''') >= xitrv.start_date_active '
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''') <= NVL(xitrv.end_date_active ,TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''')) '
      -- �ŋ敪
      || '   AND xitrv.tax_code_ex = xlv2.lookup_code '
      || '   AND xlv2.lookup_type  = ''' || cv_xxpo_tax_type || ''''
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''' ) >= xlv2.start_date_active '
      || '   AND TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''') <= NVL(xlv2.end_date_active ,TO_DATE(comm.tax_date ,''' || gc_char_d_format || ''')) ';
-- 2019/08/30 Ver1.22 Mod End
--
      -- �p�����[�^������
      IF (ir_param.assen_vendor_code.COUNT = gn_one) THEN
        -- 1���̂�
        lv_sql := lv_sql
          || '     AND xvv_a.segment1 = ''' || ir_param.assen_vendor_code(gn_one) || '''';
      ELSIF (ir_param.assen_vendor_code.COUNT > gn_one) THEN
        -- 1���ȏ�
        lv_in := fnc_get_in_statement(ir_param.assen_vendor_code);
        lv_sql := lv_sql
          || '     AND xvv_a.segment1 IN(' || lv_in || ') ';
      END IF;
      -- �p�������
      IF (ir_param.vendor_code.COUNT = gn_one) THEN
        -- 1���̂�
        lv_sql := lv_sql
          || '     AND xvv_s.segment1 = ''' || ir_param.vendor_code(gn_one) || '''';
      ELSIF (ir_param.vendor_code.COUNT > gn_one) THEN
        -- 1���ȏ�
        lv_in := fnc_get_in_statement(ir_param.vendor_code);
        lv_sql := lv_sql
          || '     AND xvv_s.segment1 IN(' || lv_in || ') ';
      END IF;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    lv_sql := lv_sql
      || ' ORDER BY'
      || '  segment1_s' -- �d����R�[�h
      || ' ,segment1_a' -- �����҃R�[�h
-- 2009/06/02 v1.16 T.Yoshimoto Add Start �{��#1516
      || ' ,attribute10' -- ���������R�[�h
-- 2009/06/02 v1.16 T.Yoshimoto Add End �{��#1516
-- 2019/08/30 Ver1.22 Add Start
      || ' ,TO_NUMBER(xlv2.attribute1)' -- �\�[�g��
-- 2019/08/30 Ver1.22 Add End
      ;
--
--      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_sql) ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref;
    IF ( ot_data_rec.COUNT = 0 ) THEN
      -- �擾�f�[�^���O���̏ꍇ
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
  /**********************************************************************************
   * Procedure Name   : prc_edit_data
   * Description      : �w�l�k�f�[�^�쐬(F-3-2)
   ***********************************************************************************/
  PROCEDURE prc_edit_data(
      ov_errbuf         OUT VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,it_data_rec       IN  tab_data_type_dtl2 -- �擾���R�[�h�Q
     ,ot_data_rec       OUT tab_data_type_dtl  -- �擾���R�[�h�Q(�ҏW��)
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_edit_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
-- 2019/08/30 Ver1.22 Add Start
    cv_lookup_koza_type CONSTANT VARCHAR2(16) := 'XXCSO1_KOZA_TYPE';
    cv_flag_y           CONSTANT VARCHAR2(1)  := 'Y';                -- �t���O:Y
    cv_flag_n           CONSTANT VARCHAR2(1)  := 'N';                -- �t���O:N
-- 2019/08/30 Ver1.22 Add End
--
    -- *** ���[�J���ϐ� ***
    ln_count      NUMBER DEFAULT 1;
    ln_loop_index NUMBER DEFAULT 0;
-- 2019/08/30 Ver1.22 Add Start
    ln_line_count NUMBER DEFAULT 0;
    ln_loop_tax   NUMBER DEFAULT 1;
-- 2019/08/30 Ver1.22 Add End
--
    lv_dept_code     VARCHAR2(4);
    lv_assen_no      VARCHAR2(4);
    lv_siire_no      VARCHAR2(4);
-- 2019/08/30 Ver1.22 Add Start
    lv_tax_code      VARCHAR2(4);
-- 2019/08/30 Ver1.22 Add End
--
    -- ���z�v�Z�p
    ln_siire                NUMBER DEFAULT 0;         -- �d�����z
    ln_kousen               NUMBER DEFAULT 0;         -- ���K���z
    ln_kobiki_gaku          NUMBER DEFAULT 0;         -- �����z
    ln_fuka                 NUMBER DEFAULT 0;         -- ���ۋ��z
--
    ln_sum_qty              NUMBER DEFAULT 0;         -- ���ɑ���
    ln_sum_conv_qty         NUMBER DEFAULT 0;         -- ���ɑ���(���Z��)
    ln_kobikigo_tanka       NUMBER DEFAULT 0;         -- ������P��
    ln_sum_siire            NUMBER DEFAULT 0;         -- �d�����z
    ln_sum_kosen            NUMBER DEFAULT 0;         -- ���K���z
    ln_sum_fuka             NUMBER DEFAULT 0;         -- ���ۋ��z
    ln_sum_sasihiki         NUMBER DEFAULT 0;         -- �������z
    ln_sum_tax_siire        NUMBER DEFAULT 0;         -- �����(�d�����z)
    ln_sum_tax_kousen       NUMBER DEFAULT 0;         -- �����(���K���z)
    ln_sum_tax_sasihiki     NUMBER DEFAULT 0;         -- �����(�������z)
    ln_sum_jun_siire        NUMBER DEFAULT 0;         -- ���d�����z
    ln_sum_jun_kosen        NUMBER DEFAULT 0;         -- �����K���z
    ln_sum_jun_sasihiki     NUMBER DEFAULT 0;         -- ���������z
--
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
    -- ����Ŏ擾�p
    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- �����
    ld_tax_date                                     DATE; -- ����Ŋ��
-- 2019/08/30 Ver1.22 Add Start
    lv_comm_price_tax_kbn fnd_lookup_values.attribute1%TYPE; -- �ŋ敪�i�W���j
    lv_comm_price_tax_kbn_1 fnd_lookup_values.attribute1%TYPE; -- �u���C�N���o�͗p�ŋ敪�i�W���j
    -- �U������擾�p
    lt_bank_name             ap_bank_branches.bank_name%TYPE;                   -- ���Z�@�֖�
    lt_bank_branch_name      ap_bank_branches.bank_branch_name%TYPE;            -- �x�X��
    lv_bank_account_type     VARCHAR2(4);                                       -- �a���敪
    lt_bank_account_num      ap_bank_accounts_all.bank_account_num%TYPE;        -- ����No
    lt_bank_account_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE; -- �������`��
--
    lv_break_flg             VARCHAR2(1);                                       -- �u���C�N�t���O
    lv_break_init_flg        VARCHAR2(1);                                       -- �u���C�N�������t���O
--
-- 2019/08/30 Ver1.22 Add End
-- Ver1.25 Add Start
    lt_invoice_t_no          VARCHAR2(14);                                      -- �o�^�ԍ�
-- Ver1.25 Add End
    -- *** ���[�J���E��O���� ***
    get_value_expt    EXCEPTION ;     -- �l�擾�G���[
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- ==========================
    --  �u���C�N�p�ϐ�������
    -- ==========================
    lv_dept_code   := it_data_rec(1).attribute10;               -- �����R�[�h
    lv_assen_no    := NVL(it_data_rec(1).segment1_a, 'NULL');   -- �����҃R�[�h
    lv_siire_no    := it_data_rec(1).segment1_s;                -- �d����R�[�h
-- 2019/08/30 Ver1.22 Add Start
    lv_tax_code    := it_data_rec(1).tax_code;                  -- �ŃR�[�h
--
    gt_tax_kbn_bd_tab.DELETE;                            -- �ŋ敪
    gt_tax_kbn_bd_1_tab.DELETE;                          -- �ŋ敪_�ŋ敪����o�͗p
    gt_p_amount_bd_tab.DELETE;                           -- �d�����z(�Ŕ�)
    gt_p_amount_tax_bd_tab.DELETE;                       -- �d�������
    gt_unit_price_rate_bd_tab.DELETE;                    -- ���K���z(�Ŕ�)
    gt_unit_price_rate_tax_bd_tab.DELETE;                -- ���K�����
    gt_l_unit_price_rate_bd_tab.DELETE;                  -- ���ۋ�
    gt_l_u_price_rate_tax_bd_tab.DELETE;                 -- ���ۋ������
    gt_tax_exc_amount_bd_tab.DELETE;                     -- ���v(�Ŕ����z)
    gt_ded_amount_tax_bd_tab.DELETE;                     -- ���v(�����)
-- Ver1.25 Add Start
    gt_tax_rate_tab.DELETE;                              -- �ŗ�
    gt_kousen_tax_rate_tab.DELETE;                       -- �ŗ�(���K)
-- Ver1.25 Add End
--
    lv_break_flg      := cv_flag_y;                      -- �u���C�N�t���O
    lv_break_init_flg := cv_flag_n;                      -- �u���C�N�������t���O
-- 2019/08/30 Ver1.22 Add End
--
    <<main_data_loop>>
    FOR ln_loop_index IN 1..it_data_rec.COUNT LOOP
--
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
      -- ====================================================
      -- ����擾
      -- ====================================================
      -- ������擾
        ld_tax_date := FND_DATE.STRING_TO_DATE (it_data_rec(ln_loop_index).tax_date ,gc_char_d_format);
--
      -- ���������ł��擾
      BEGIN
        SELECT
          flv.lookup_code
-- 2019/08/30 Ver1.22 Add Start
         ,flv.attribute1
-- 2019/08/30 Ver1.22 Add End
        INTO
          lv_tax
-- 2019/08/30 Ver1.22 Add Start
         ,lv_comm_price_tax_kbn
-- 2019/08/30 Ver1.22 Add End
        FROM
          xxcmn_lookup_values2_v flv
        WHERE
          flv.lookup_type = gv_xxcmn_consumption_tax_rate
        AND ((flv.start_date_active <= ld_tax_date )
          OR (flv.start_date_active IS NULL))
        AND ((flv.end_date_active   >= ld_tax_date )
          OR (flv.end_date_active   IS NULL));
--
        EXCEPTION
              -- �f�[�^�Ȃ�
          WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�Z�b�g
            lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                                  ,'APP-XXPO-10127'
                                                  ,'ENTRY'
                                                  ,'����ŗ�'
                                                  ,'TABLE'
                                                  ,'xxcmn_lookup_values2_v' ||  '�A' || it_data_rec(ln_loop_index).tax_date ) ;
            lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
--
      -- ����ŌW��
      gn_tax := TO_NUMBER(lv_tax) / 100;
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
--
-- 2019/08/30 Ver1.22 Mod Start
      --���񌏐��擾
      IF (ln_line_count = 0) THEN
        ln_line_count := 1;
      END IF;
-- 2019/08/30 Ver1.22 Mod End
--
      -- ==========================
      --  ���R�[�h���u���C�N
      -- ==========================
-- Ver1.25 Mod Start
--      -- �����R�[�h/�d����/������/�ŃR�[�h���ύX�����ꍇ
--      IF ( ( lv_dept_code <> it_data_rec(ln_loop_index).attribute10 )
--        OR ( lv_assen_no <> NVL(it_data_rec(ln_loop_index).segment1_a, 'NULL') )
      -- �d����/������/�ŃR�[�h���ύX�����ꍇ
      IF ( 
           ( lv_assen_no <> NVL(it_data_rec(ln_loop_index).segment1_a, 'NULL') )
-- Ver1.25 Mod End
-- 2019/08/30 Ver1.22 Mod Start
--        OR ( lv_siire_no <> it_data_rec(ln_loop_index).segment1_s ) ) THEN
        OR ( lv_siire_no <> it_data_rec(ln_loop_index).segment1_s )
        OR ( lv_tax_code <> it_data_rec(ln_loop_index).tax_code) ) THEN
-- 2019/08/30 Ver1.22 Mod End
--
-- 2019/08/30 Ver1.22 Add Start
        -- ���׍s�����J�E���g
--        ln_line_count := ln_line_count + 1;
--
        -- �d���悪�ύX�����ꍇ
        IF (lv_siire_no <> NVL(it_data_rec(ln_loop_index).segment1_s, 'NULL')) THEN
          -- �u���C�N�t���OON
          lv_break_flg      := cv_flag_y;
          -- �u���C�N�������t���OOFF
          lv_break_init_flg := cv_flag_n;
--
          -- (���׍s��) / (1�y�[�W�ő�s��)�̗]�肪�\���\���א����傫���ꍇ
          IF ( MOD(ln_line_count , gn_max_line_9) > gn_line_count ) THEN
            -- ���[���y�[�W�t���OON
            ot_data_rec(ln_count).break_page_flg := cv_flag_y;
          ELSE
            -- ���[���y�[�W�t���OOFF
            ot_data_rec(ln_count).break_page_flg := cv_flag_n;
          END IF;
--
          -- ���׍s��������
          ln_line_count := 0;
--
        ELSE
          -- ���׍s�����J�E���g
            ln_line_count := ln_line_count + 1;
--
        END IF;
--
        -- �H��R�[�h���A�U��������擾
        BEGIN
          SELECT abb.bank_name                  bank_name                -- ���Z�@�֖�
                ,abb.bank_branch_name           bank_branch_name         -- �x�X��
                ,flv.meaning                    bank_account_type        -- �a���敪��
                ,aba.bank_account_num           bank_account_num         -- ����No
                ,aba.account_holder_name_alt    bank_account_name_alt    -- �������`��
-- Ver1.25 Add Start
                ,pvsa_sales.attribute8 || pvsa_sales.attribute9 invoice_t_no   -- �o�^�ԍ�
-- Ver1.25 Add End
          INTO   lt_bank_name
                ,lt_bank_branch_name
                ,lv_bank_account_type
                ,lt_bank_account_num
                ,lt_bank_account_name_alt
-- Ver1.25 Add Start
                ,lt_invoice_t_no
-- Ver1.25 Add End
          FROM   ap_bank_account_uses_all  abaua       -- �����g�p���e�[�u��
                ,ap_bank_accounts_all      aba         -- ��s����
                ,ap_bank_branches          abb         -- ��s�x�X
                ,po_vendors                pv          -- �d����
                ,po_vendor_sites_all       pvsa_sales  -- �d����T�C�g(�c��)
                ,po_vendor_sites_all       pvsa_mfg    -- �d����T�C�g(���Y)
                ,xxcmn_lookup_values2_v    flv         -- �N�C�b�N�R�[�h�i������ʁj
          WHERE  abaua.external_bank_account_id = aba.bank_account_id
          AND    aba.bank_branch_id             = abb.bank_branch_id
          AND    ld_tax_date                    BETWEEN abaua.start_date
                                                AND     NVL(abaua.end_date ,ld_tax_date)
          AND    abaua.vendor_id                = pv.vendor_id
          AND    abaua.vendor_id                = pvsa_sales.vendor_id
          AND    abaua.vendor_site_id           = pvsa_sales.vendor_site_id
          AND    pvsa_sales.org_id              = gn_sales_org_id
          AND    pvsa_sales.vendor_site_code    = pvsa_mfg.attribute5
          AND    pvsa_mfg.org_id                = gn_sales_class
          AND    pvsa_mfg.vendor_site_code      = it_data_rec(ln_loop_index-1).factory_code -- �H��R�[�h
          AND    aba.bank_account_type          = flv.lookup_code
          AND    flv.lookup_type                = cv_lookup_koza_type
          AND    ld_tax_date                    BETWEEN flv.start_date_active
                                                AND     NVL(flv.end_date_active ,ld_tax_date)
          ;
--
          EXCEPTION
                -- �f�[�^�Ȃ�
            WHEN NO_DATA_FOUND THEN
            -- ���b�Z�[�W�Z�b�g
              lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                                    ,cv_msg_po_10296
                                                    ,cv_tkn_vendor
                                                    ,it_data_rec(ln_loop_index-1).segment1_s
                                                    ,cv_tkn_factory
                                                    ,it_data_rec(ln_loop_index-1).factory_code ) ;
              lv_retcode  := gv_status_error ;
            RAISE get_value_expt ;
        END;
-- 2019/08/30 Ver1.22 Add End
--
        --�������z
        ln_sum_sasihiki     := ln_sum_siire - ln_sum_kosen - ln_sum_fuka;
--
-- 2009/06/02 v1.16 T.Yoshimoto Del Start �{��#1516
        --�����(�d�����z)
        --ln_sum_tax_siire    := ROUND(NVL(ln_sum_siire, 0) * NVL(gn_tax , 0) ,0);
        --�����(���K���z)
        --ln_sum_tax_kousen   := ROUND(NVL(ln_sum_kosen, 0) * NVL(gn_tax , 0) ,0);
-- 2009/06/02 v1.16 T.Yoshimoto Del End �{��#1516
--
        --�����(�������z)
        ln_sum_tax_sasihiki := ln_sum_tax_siire - ln_sum_tax_kousen;
--
        --���d�����z
        ln_sum_jun_siire    := ln_sum_siire + ln_sum_tax_siire;
        --�����K���z
        ln_sum_jun_kosen    := ln_sum_kosen + ln_sum_tax_kousen;
        --���������z
        ln_sum_jun_sasihiki := ln_sum_sasihiki + ln_sum_tax_sasihiki;
--
        -- ==========================
        --  �ҏW�ヌ�R�[�h�Ƃ��Ċi�[
        -- ==========================
        ot_data_rec(ln_count).segment1_s           := it_data_rec(ln_loop_index-1).segment1_s;       --�d����ԍ�
        ot_data_rec(ln_count).vendor_name          := it_data_rec(ln_loop_index-1).vendor_name;      --�d���於��
        ot_data_rec(ln_count).zip                  := it_data_rec(ln_loop_index-1).zip;              --�X�֔ԍ�
        ot_data_rec(ln_count).address_line1        := it_data_rec(ln_loop_index-1).address_line1;    --�����Z���P
        ot_data_rec(ln_count).address_line2        := it_data_rec(ln_loop_index-1).address_line2;    --�����Z���Q
        ot_data_rec(ln_count).phone                := it_data_rec(ln_loop_index-1).phone;            --�����d�b
        ot_data_rec(ln_count).fax                  := it_data_rec(ln_loop_index-1).fax;              --�����FAX
--
        ot_data_rec(ln_count).segment1_a           := it_data_rec(ln_loop_index-1).segment1_a;       --�����Ҏd����ԍ�
        ot_data_rec(ln_count).vendor_full_name     := it_data_rec(ln_loop_index-1).vendor_full_name; --�����Җ��P
--
        ot_data_rec(ln_count).attribute10          := it_data_rec(ln_loop_index-1).attribute10;      --�����R�[�h
--
        ot_data_rec(ln_count).quantity             := ln_sum_qty;                                    --����
        ot_data_rec(ln_count).purchase_amount      := ln_sum_siire;                                  --�d�����z
        ot_data_rec(ln_count).attribute5           := ln_sum_kosen;                                  --�a����K���z
        ot_data_rec(ln_count).attribute8           := ln_sum_fuka;                                   --���ۋ��z
-- Ver1.25 Add Start
        ln_sum_tax_siire                           := ROUND(NVL(ln_sum_siire, 0) * it_data_rec(ln_loop_index-1).tax ,0);
        ln_sum_tax_kousen                          := ROUND(NVL(ln_sum_kosen, 0) * gn_tax ,0);
-- Ver1.25 Add End
        ot_data_rec(ln_count).purchase_amount_tax  := ln_sum_tax_siire;                              --�d�����z(�����)
        ot_data_rec(ln_count).attribute5_tax       := ln_sum_tax_kousen;                             --�a������K���z(�����)
--
-- 2019/08/30 Ver1.22 Add Start
        ot_data_rec(ln_count).purchase_tax_kbn      := it_data_rec(ln_loop_index-1).attribute3;      --�d���ŋ敪
        ot_data_rec(ln_count).comm_price_tax_kbn    := lv_comm_price_tax_kbn_1;                      --���K�ŋ敪
--
        ot_data_rec(ln_count).bank_name             := lt_bank_name;                                 --���Z�@�֖�
        ot_data_rec(ln_count).bank_branch_name      := lt_bank_branch_name;                          --�x�X��
        ot_data_rec(ln_count).bank_account_type     := lv_bank_account_type;                         --�a���敪
        ot_data_rec(ln_count).bank_account_num      := lt_bank_account_num;                          --����No
        ot_data_rec(ln_count).bank_account_name_alt := lt_bank_account_name_alt;                     --�������`��
--
-- 2019/08/30 Ver1.22 Add End
-- Ver1.25 Add Start
        ot_data_rec(ln_count).invoice_t_no          := lt_invoice_t_no;                              --�o�^�ԍ�
-- Ver1.25 Add End
        -- �u���C�N�p�ϐ��֑��
        lv_dept_code   := it_data_rec(ln_loop_index).attribute10;
        lv_assen_no    := NVL(it_data_rec(ln_loop_index).segment1_a, 'NULL');
        lv_siire_no    := it_data_rec(ln_loop_index).segment1_s;
-- 2019/08/30 Ver1.22 Add Start
        lv_tax_code    := it_data_rec(ln_loop_index).tax_code;
-- 2019/08/30 Ver1.22 Add End
--
        -- ���z�v�Z�p�ϐ��̏�����
        ln_siire             := 0;  -- �d�����z
        ln_kousen            := 0;  -- ���K���z
        ln_kobiki_gaku       := 0;  -- �����z
        ln_fuka              := 0;  -- ���ۋ��z
        ln_sum_qty           := 0;  -- ���ɑ���(���Z��)
        ln_kobikigo_tanka    := 0;  -- ������P��
        ln_sum_siire         := 0;  -- �d�����z
        ln_sum_kosen         := 0;  -- ���K���z
        ln_sum_fuka          := 0;  -- ���ۋ��z
        ln_sum_sasihiki      := 0;  -- �������z
        ln_sum_tax_siire     := 0;  -- �����(�d�����z)
        ln_sum_tax_kousen    := 0;  -- �����(���K���z)
        ln_sum_tax_sasihiki  := 0;  -- �����(�������z)
        ln_sum_jun_siire     := 0;  -- ���d�����z
        ln_sum_jun_kosen     := 0;  -- �����K���z
        ln_sum_jun_sasihiki  := 0;  -- ���������z
--
        -- �J�E���g�A�b�v
        ln_count := ln_count + 1;
      END IF;
--
      -- ==========================
      --  �o�͍��ڂ��v�Z
      -- ==========================
      -- ������т̏ꍇ
      IF (it_data_rec(ln_loop_index).txns_type = '1') THEN
-- 2009/08/10 v1.18 T.Yoshimoto Mod Start �{��#1596
/*
        -- �d�����z(�؎̂�)
        ln_siire :=  TRUNC( NVL(it_data_rec(ln_loop_index).quantity, 0) *
                            NVL(it_data_rec(ln_loop_index).unit_price, 0) );
*/
        -- �d�����z(�l�̌ܓ�)
        ln_siire :=  ROUND( NVL(it_data_rec(ln_loop_index).quantity, 0) *
                            NVL(it_data_rec(ln_loop_index).unit_price, 0), 0);
-- 2009/08/10 v1.18 T.Yoshimoto Mod End �{��#1596
--
        -- ���K���z
        -- ���K�敪���u���v�̏ꍇ
        IF ( it_data_rec(ln_loop_index).kousen_k = '2' ) THEN
          -- �a������K���z���P��*����*���K/100
          ln_kousen := TRUNC( it_data_rec(ln_loop_index).kobiki_mae * 
                              NVL(it_data_rec(ln_loop_index).quantity, 0) * NVL(it_data_rec(ln_loop_index).kousen, 0) / 100 );
        -- ���K�敪���u�~�v�̏ꍇ
        ELSIF ( it_data_rec(ln_loop_index).kousen_k = '1' ) THEN
          -- �a����K���z�����K*����
          ln_kousen := TRUNC( NVL(it_data_rec(ln_loop_index).kousen, 0) * 
                              NVL(it_data_rec(ln_loop_index).quantity, 0));
        ELSE
          ln_kousen := 0;
        END IF;
--
        -- ���ۋ��z
        -- ���ۋ��敪���u���v�̏ꍇ
        IF ( it_data_rec(ln_loop_index).fukakin_k = '2' ) THEN
--
          -- �����z���P�� * ���� * ������ / 100
          ln_kobiki_gaku := it_data_rec(ln_loop_index).kobiki_mae * NVL(it_data_rec(ln_loop_index).quantity, 0) * 
                              NVL(it_data_rec(ln_loop_index).kobiki_rate,0) / 100;
          -- ���ۋ��z���i�P�� * ���� - �����z�j* ���ۗ� / 100
          ln_fuka := TRUNC(( it_data_rec(ln_loop_index).kobiki_mae * 
                             NVL(it_data_rec(ln_loop_index).quantity, 0) - ln_kobiki_gaku) * 
                             NVL(it_data_rec(ln_loop_index).fukakin,0) / 100);
--
        -- ���ۋ��敪���u�~�v�̏ꍇ
        ELSIF ( it_data_rec(ln_loop_index).fukakin_k = '1' ) THEN
          -- ���ۋ��z�����ۋ�*����
          ln_fuka := TRUNC( NVL(it_data_rec(ln_loop_index).fukakin,0) * NVL(it_data_rec(ln_loop_index).quantity, 0) );
        ELSE
          ln_fuka := 0;
        END IF;
--
      -- ��������ԕi/�����Ȃ��ԕi�̏ꍇ
      ELSE
--
-- 2009/08/10 v1.18 T.Yoshimoto Mod Start �{��#1596
/*
        --�d�����z(�؎̂�)
        ln_siire  :=  TRUNC( NVL(it_data_rec(ln_loop_index).purchase_amount, 0));
*/
        --�d�����z(�l�̌ܓ�)
        ln_siire  :=  ROUND( NVL(it_data_rec(ln_loop_index).purchase_amount, 0), 0);
-- 2009/08/10 v1.18 T.Yoshimoto Mod End �{��#1596
--
        --���K���z
        ln_kousen := it_data_rec(ln_loop_index).attribute5;
--
        --���ۋ��z
        ln_fuka   := it_data_rec(ln_loop_index).attribute8;
--
      END IF;
--
      -- ==========================
      --  �K�v���ڂ��T�}���[
      -- ==========================
      --�����(�d�����z)
-- Ver1.25 Del Start
---- 2019/08/30 Ver1.22 Mod Start
----      ln_sum_tax_siire    := ln_sum_tax_siire + (ROUND(NVL(ln_siire, 0) * gn_tax ,0));
--      ln_sum_tax_siire    := ln_sum_tax_siire + (ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0));
---- 2019/08/30 Ver1.22 Mod End
--      --�����(���K���z)
--      ln_sum_tax_kousen   := ln_sum_tax_kousen + (ROUND(NVL(ln_kousen, 0) * gn_tax ,0));
-- Ver1.25 Del End
      -- ���ɑ��������Z
      ln_sum_qty          := ln_sum_qty + it_data_rec(ln_loop_index).quantity;
      -- �d�����z�����Z
      ln_sum_siire        := ln_sum_siire + ln_siire;
      -- ���K���z�����Z
      ln_sum_kosen        := ln_sum_kosen + ln_kousen;
      -- ���ۋ��z�����Z
      ln_sum_fuka         := ln_sum_fuka + ln_fuka;
--
-- 2019/08/30 Ver1.22 Add Start
      -- �ŋ敪����\�v�Z
      <<tax_kbn_loop>>
      FOR ln_loop_tax IN 1..gt_description_tbl.COUNT LOOP
        -- �J�E���g�A�b�v
        gn_tax_kbn := gn_tax_kbn + 1;
--
        -- �u���C�N��̏ꍇ
        IF(lv_break_flg = cv_flag_y) THEN
          -- �l�ݒ�
          gt_tax_kbn_bd_tab(gn_tax_kbn)             := gt_description_tbl(ln_loop_tax);  -- �ŋ敪
          gt_tax_kbn_bd_1_tab(gn_tax_kbn)           := gt_attribute2_tbl(ln_loop_tax);   -- �ŋ敪_�ŋ敪����o�͗p
          gt_p_amount_bd_tab(gn_tax_kbn)            := 0;                                -- �d�����z(�Ŕ�)
          gt_p_amount_tax_bd_tab(gn_tax_kbn)        := 0;                                -- �d�������
          gt_unit_price_rate_bd_tab(gn_tax_kbn)     := 0;                                -- ���K���z(�Ŕ�)
          gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) := 0;                                -- ���K�����
          gt_l_unit_price_rate_bd_tab(gn_tax_kbn)   := 0;                                -- ���ۋ�
          gt_l_u_price_rate_tax_bd_tab(gn_tax_kbn)  := 0;                                -- ���ۋ������
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := 0;                                -- ���v(�Ŕ����z)
          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      := 0;                                -- ���v(�����)
-- Ver1.25 Add Start
          gt_tax_rate_tab(gn_tax_kbn)               := 0;                                -- �ŗ�
          gt_kousen_tax_rate_tab(gn_tax_kbn)        := 0;                                -- �ŗ�(���K)
-- Ver1.25 Add End
        -- �u���C�N���Ă��Ȃ��ꍇ
        ELSE
          -- ������
          IF (lv_break_init_flg = cv_flag_n) THEN
            gn_tax_kbn := gn_tax_kbn - gt_description_tbl.COUNT;
            lv_break_init_flg := cv_flag_y;
          END IF;
        END IF;
--
        -- �ŋ敪���d���ŋ敪�ƌ��K�ŋ敪�ƈ�v�����ꍇ �����ۋ��ɂďo�͂���ׁA�ŋ敪���ΏۊO�̃f�[�^������
        IF (gt_description_tbl(ln_loop_tax) = it_data_rec(ln_loop_index).tax_kbn)
          AND (gt_description_tbl(ln_loop_tax) <> gv_tax_kbn_0000)
          AND (it_data_rec(ln_loop_index).attribute3 = lv_comm_price_tax_kbn) THEN
          -- ���z�̐ݒ�
          gt_p_amount_bd_tab(gn_tax_kbn)            := gt_p_amount_bd_tab(gn_tax_kbn)            + ln_siire;                                                    -- �d�����z(�Ŕ�)
-- Ver1.25 Add Start
          gt_tax_rate_tab(gn_tax_kbn)               := it_data_rec(ln_loop_index).tax;                                                                          -- �ŗ�
-- Ver1.25 Add End
-- Ver1.25 Del Start
--          gt_p_amount_tax_bd_tab(gn_tax_kbn)        := gt_p_amount_tax_bd_tab(gn_tax_kbn)        + ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0); -- �d�������
-- Ver1.25 Del End
          gt_unit_price_rate_bd_tab(gn_tax_kbn)     := gt_unit_price_rate_bd_tab(gn_tax_kbn)     + (ln_kousen * -1);                                            -- ���K���z(�Ŕ�)(�}�C�i�X�\��)
-- Ver1.25 Del Start
--          gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) := gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) + (ROUND(NVL(ln_kousen, 0) * gn_tax ,0) * -1);                -- ���K�����(�}�C�i�X�\��)
-- Ver1.25 Del End
          -- �d�����z(�Ŕ�) + ���K���z(�Ŕ�)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + ln_siire + (ln_kousen * -1);                                 -- ���v(�Ŕ����z)
-- Ver1.25 Del Start
--          -- �d������� + ���K�����
--          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      :=   gt_ded_amount_tax_bd_tab(gn_tax_kbn)
--                                                       + (ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0))
--                                                       + ((ROUND(NVL(ln_kousen, 0) * gn_tax ,0)) * -1);                                                         -- ���v(�����)
-- Ver1.25 Del End
        END IF;
--
        -- �ŋ敪���d���ŋ敪�ƈ�v���A���K�ŋ敪�ƕs��v�ƂȂ�ꍇ �����ۋ��ɂďo�͂���ׁA�ŋ敪���ΏۊO�̃f�[�^������
        IF (gt_description_tbl(ln_loop_tax) = it_data_rec(ln_loop_index).tax_kbn)
          AND (gt_description_tbl(ln_loop_tax) <> gv_tax_kbn_0000)
          AND (it_data_rec(ln_loop_index).attribute3 <> lv_comm_price_tax_kbn) THEN
          -- ���z�̐ݒ�
          gt_p_amount_bd_tab(gn_tax_kbn)            := gt_p_amount_bd_tab(gn_tax_kbn)            + ln_siire;                                                    -- �d�����z(�Ŕ�)
-- Ver1.25 Add Start
          gt_tax_rate_tab(gn_tax_kbn)               := it_data_rec(ln_loop_index).tax;                                                                          -- �ŗ�
-- Ver1.25 Add End
-- Ver1.25 Del Start
--          gt_p_amount_tax_bd_tab(gn_tax_kbn)        := gt_p_amount_tax_bd_tab(gn_tax_kbn)        + ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0); -- �d�������
-- Ver1.25 Del End
          -- �d�����z(�Ŕ�) + ���K���z(�Ŕ�)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + ln_siire;                                                    -- ���v(�Ŕ����z)
-- Ver1.25 Del Start
--          -- �d������� + ���K�����
--          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      :=   gt_ded_amount_tax_bd_tab(gn_tax_kbn)
--                                                       + (ROUND(NVL(ln_siire, 0) * it_data_rec(ln_loop_index).tax ,0));                                         -- ���v(�����)
-- Ver1.25 Del End
        END IF;
--
        -- �ŋ敪�����K�ŋ敪�ƈ�v���A�d���ŋ敪�ƕs��v�ƂȂ�ꍇ �����ۋ��ɂďo�͂���ׁA�ŋ敪���ΏۊO�̃f�[�^������
        IF (gt_description_tbl(ln_loop_tax) = lv_comm_price_tax_kbn)
          AND (gt_description_tbl(ln_loop_tax) <> gv_tax_kbn_0000)
          AND (it_data_rec(ln_loop_index).attribute3 <> lv_comm_price_tax_kbn) THEN
          gt_unit_price_rate_bd_tab(gn_tax_kbn)     := gt_unit_price_rate_bd_tab(gn_tax_kbn)     + (ln_kousen * -1);                                            -- ���K���z(�Ŕ�)(�}�C�i�X�\��)
-- Ver1.25 Add Start
          gt_kousen_tax_rate_tab(gn_tax_kbn)        := gn_tax;                                                                                                  -- �ŗ�(���K)
-- Ver1.25 Add End
-- Ver1.25 Del Start
--          gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) := gt_unit_price_rate_tax_bd_tab(gn_tax_kbn) + (ROUND(NVL(ln_kousen, 0) * gn_tax ,0) * -1);                -- ���K�����(�}�C�i�X�\��)
-- Ver1.25 Del End
          -- �d�����z(�Ŕ�) + ���K���z(�Ŕ�)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + (ln_kousen * -1);                                            -- ���v(�Ŕ����z)
-- Ver1.25 Del Start
--          -- �d������� + ���K�����
--          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      :=   gt_ded_amount_tax_bd_tab(gn_tax_kbn)
--                                                       + ((ROUND(NVL(ln_kousen, 0) * gn_tax ,0)) * -1);                                                         -- ���v(�����)
-- Ver1.25 Del End
        END IF;
--
        -- �ŋ敪���ΏۊO�̏ꍇ
        IF (gt_description_tbl(ln_loop_tax) = gv_tax_kbn_0000 ) THEN
          gt_l_unit_price_rate_bd_tab(gn_tax_kbn)   := gt_l_unit_price_rate_bd_tab(gn_tax_kbn)   + (ln_fuka * -1);                                              -- ���ۋ�(�}�C�i�X�\��)
          gt_l_u_price_rate_tax_bd_tab(gn_tax_kbn)  := gt_l_u_price_rate_tax_bd_tab(gn_tax_kbn)  + (0 * -1);                                                    -- ���ۋ������(�}�C�i�X�\��)
          gt_tax_exc_amount_bd_tab(gn_tax_kbn)      := gt_tax_exc_amount_bd_tab(gn_tax_kbn)      + (ln_fuka * -1);                                              -- ���v(�Ŕ����z)
-- Ver1.25 Del Start
--          gt_ded_amount_tax_bd_tab(gn_tax_kbn)      := gt_ded_amount_tax_bd_tab(gn_tax_kbn)      + (0 * -1);                                                    -- ���v(�����)
-- Ver1.25 Del End
        END IF;
--
      END LOOP tax_kbn_loop;
--
      -- �u���C�N�t���OOFF
      lv_break_flg := cv_flag_n;
      -- �u���C�N�������t���OOFF
      lv_break_init_flg := cv_flag_n;
      --�u���C�N���o�͗p���K�ŋ敪�ێ�
      lv_comm_price_tax_kbn_1 := lv_comm_price_tax_kbn;
--
-- 2019/08/30 Ver1.22 Add End
    END LOOP main_data_loop ;
--
--
    IF ( it_data_rec.COUNT > 0 ) THEN
--
      ln_loop_index := it_data_rec.COUNT;
--
      --�������z
      ln_sum_sasihiki     := ln_sum_siire - ln_sum_kosen - ln_sum_fuka;
--
      --�����(�������z)
      ln_sum_tax_sasihiki := ln_sum_tax_siire - ln_sum_tax_kousen;
--
      --���d�����z
      ln_sum_jun_siire    := ln_sum_siire + ln_sum_tax_siire;
      --�����K���z
      ln_sum_jun_kosen    := ln_sum_kosen + ln_sum_tax_kousen;
      --���������z
      ln_sum_jun_sasihiki := ln_sum_sasihiki + ln_sum_tax_sasihiki;
--
-- 2019/08/30 Ver1.22 Add Start
      -- �H��R�[�h���A�U��������擾
      BEGIN
        SELECT abb.bank_name                  bank_name                -- ���Z�@�֖�
              ,abb.bank_branch_name           bank_branch_name         -- �x�X��
              ,flv.meaning                    bank_account_type        -- �a���敪��
              ,aba.bank_account_num           bank_account_num         -- ����No
              ,aba.account_holder_name_alt    bank_account_name_alt    -- �������`��
-- Ver1.25 Add Start
              ,pvsa_sales.attribute8 || pvsa_sales.attribute9 invoice_t_no   -- �o�^�ԍ�
-- Ver1.25 Add End
        INTO   lt_bank_name
              ,lt_bank_branch_name
              ,lv_bank_account_type
              ,lt_bank_account_num
              ,lt_bank_account_name_alt
-- Ver1.25 Add Start
              ,lt_invoice_t_no
-- Ver1.25 Add End
        FROM   ap_bank_account_uses_all  abaua       -- �����g�p���e�[�u��
              ,ap_bank_accounts_all      aba         -- ��s����
              ,ap_bank_branches          abb         -- ��s�x�X
              ,po_vendors                pv          -- �d����
              ,po_vendor_sites_all       pvsa_sales  -- �d����T�C�g(�c��)
              ,po_vendor_sites_all       pvsa_mfg    -- �d����T�C�g(���Y)
              ,xxcmn_lookup_values2_v    flv         -- �N�C�b�N�R�[�h�i������ʁj
        WHERE  abaua.external_bank_account_id = aba.bank_account_id
        AND    aba.bank_branch_id             = abb.bank_branch_id
-- 2019/11/12 Ver1.24 Add Start
        AND    ld_tax_date                    BETWEEN abaua.start_date
                                              AND     NVL(abaua.end_date ,ld_tax_date)
-- 2019/11/12 Ver1.24 Add End
        AND    abaua.vendor_id                = pv.vendor_id
        AND    abaua.vendor_id                = pvsa_sales.vendor_id
        AND    abaua.vendor_site_id           = pvsa_sales.vendor_site_id
        AND    pvsa_sales.org_id              = gn_sales_org_id
        AND    pvsa_sales.vendor_site_code    = pvsa_mfg.attribute5
        AND    pvsa_mfg.org_id                = gn_sales_class
        AND    pvsa_mfg.vendor_site_code      = it_data_rec(ln_loop_index).factory_code -- �H��R�[�h
        AND    aba.bank_account_type          = flv.lookup_code
        AND    flv.lookup_type                = cv_lookup_koza_type
        AND    ld_tax_date                    BETWEEN flv.start_date_active
                                              AND     NVL(flv.end_date_active ,ld_tax_date)
        ;
--
        EXCEPTION
          -- �f�[�^�Ȃ�
          WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�Z�b�g
            lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                                  ,cv_msg_po_10296
                                                  ,cv_tkn_vendor
                                                  ,it_data_rec(ln_loop_index).segment1_s
                                                  ,cv_tkn_factory
                                                  ,it_data_rec(ln_loop_index).factory_code ) ;
            lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
-- 2019/08/30 Ver1.22 Add End
      -- ==========================
      --  �ҏW�ヌ�R�[�h�Ƃ��Ċi�[
      -- ==========================
      ot_data_rec(ln_count).segment1_s           := it_data_rec(ln_loop_index).segment1_s;       --�d����ԍ�
      ot_data_rec(ln_count).vendor_name          := it_data_rec(ln_loop_index).vendor_name;      --�d���於��
      ot_data_rec(ln_count).zip                  := it_data_rec(ln_loop_index).zip;              --�X�֔ԍ�
      ot_data_rec(ln_count).address_line1        := it_data_rec(ln_loop_index).address_line1;    --�����Z���P
      ot_data_rec(ln_count).address_line2        := it_data_rec(ln_loop_index).address_line2;    --�����Z���Q
      ot_data_rec(ln_count).phone                := it_data_rec(ln_loop_index).phone;            --�����d�b
      ot_data_rec(ln_count).fax                  := it_data_rec(ln_loop_index).fax;              --�����FAX
--
      ot_data_rec(ln_count).segment1_a           := it_data_rec(ln_loop_index).segment1_a;       --�����Ҏd����ԍ�
      ot_data_rec(ln_count).vendor_full_name     := it_data_rec(ln_loop_index).vendor_full_name; --�����Җ��P
--
      ot_data_rec(ln_count).attribute10          := it_data_rec(ln_loop_index).attribute10;      --�����R�[�h
--
      ot_data_rec(ln_count).quantity             := ln_sum_qty;                                    --����
      ot_data_rec(ln_count).purchase_amount      := ln_sum_siire;                                  --�d�����z
      ot_data_rec(ln_count).attribute5           := ln_sum_kosen;                                  --�a����K���z
      ot_data_rec(ln_count).attribute8           := ln_sum_fuka;                                   --���ۋ��z
-- Ver1.25 Add Start
      ln_sum_tax_siire                           := ROUND(NVL(ln_sum_siire, 0) * it_data_rec(ln_loop_index).tax ,0);
      ln_sum_tax_kousen                          := ROUND(NVL(ln_sum_kosen, 0) * gn_tax ,0);
-- Ver1.25 Add End
      ot_data_rec(ln_count).purchase_amount_tax  := ln_sum_tax_siire;                              --�d�����z(�����)
      ot_data_rec(ln_count).attribute5_tax       := ln_sum_tax_kousen;                             --�a������K���z(�����)
--
-- 2019/08/30 Ver1.22 Add Start
-- 2019/10/18 Ver1.23 H.Ishii Mod Start
--      ot_data_rec(ln_count).purchase_tax_kbn      := it_data_rec(ln_loop_index-1).attribute3;      --�d���ŋ敪
      ot_data_rec(ln_count).purchase_tax_kbn      := it_data_rec(ln_loop_index).attribute3;        --�d���ŋ敪
-- 2019/10/18 Ver1.23 H.Ishii Mod End
      ot_data_rec(ln_count).comm_price_tax_kbn    := lv_comm_price_tax_kbn;                        --���K�ŋ敪
--
      ot_data_rec(ln_count).bank_name             := lt_bank_name;                                 --���Z�@�֖�
      ot_data_rec(ln_count).bank_branch_name      := lt_bank_branch_name;                          --�x�X��
      ot_data_rec(ln_count).bank_account_type     := lv_bank_account_type;                         --�a���敪
      ot_data_rec(ln_count).bank_account_num      := lt_bank_account_num;                          --����No
      ot_data_rec(ln_count).bank_account_name_alt := lt_bank_account_name_alt;                     --�������`��
--
-- Ver1.25 Add Start
      ot_data_rec(ln_count).invoice_t_no          := lt_invoice_t_no;                              --�o�^�ԍ�
-- Ver1.25 Add End
      -- (���׍s��) / (1�y�[�W�ő�s��)�̗]�肪�\���\���א����傫���ꍇ
      IF ( MOD(ln_line_count ,gn_max_line_9) > gn_line_count ) THEN
        -- �ŏI�d����̒��[���y�[�W�t���OON
        gv_break_page_flg := cv_flag_y;
      ELSE
        -- ���[���y�[�W�t���OOFF
        gv_break_page_flg := cv_flag_n;
      END IF;
--
-- 2019/08/30 Ver1.22 Add End
    END IF;
--
-- 2013/07/05 v1.21 R.Watanabe Add Start E_�{�ғ�_10839
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode ;
-- 2013/07/05 v1.21 R.Watanabe Add End E_�{�ғ�_10839
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_edit_data;
-- 2009/05/26 v1.15 T.Yoshimoto Add End
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,ir_param          IN  rec_param_data    -- �p�����[�^
     ,it_data_rec       IN  tab_data_type_dtl -- �擾���R�[�h�Q
     ,ot_xml_data_table OUT XML_DATA          -- XML�f�[�^
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           VARCHAR2(100) DEFAULT '*' ;            -- �����l
    lc_break_null           VARCHAR2(100) DEFAULT '**' ;           -- �m�t�k�k����
-- 2019/08/30 Ver1.22 Add Start
    cv_flag_y               CONSTANT VARCHAR2(1)  := 'Y';          -- �t���O:Y
-- 2019/08/30 Ver1.22 Add End
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_company_code         VARCHAR2(100) DEFAULT lc_break_init;   -- ��ЃR�[�h
-- add start 1.10
    ln_vendor_name_len      NUMBER;                                -- ����於�̕�����
-- add end 1.10
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;  -- �擾���R�[�h�Ȃ�
--
    lv_from_year            VARCHAR2(4); -- ���ԊJ�n�F�N
    lv_from_month           VARCHAR2(2); -- ���ԊJ�n�F��
    lv_from_date            VARCHAR2(2); -- ���ԊJ�n�F��
    lv_to_year              VARCHAR2(4); -- ���ԏI���F�N
    lv_to_month             VARCHAR2(2); -- ���ԏI���F��
    lv_to_date              VARCHAR2(2); -- ���ԏI���F��
-- 2019/08/30 Ver1.22 Mod Start
--    lv_to_year_yy           VARCHAR2(2); -- ���ԏI���F�N(YY)
    lv_year_yyyy            VARCHAR2(4); -- ���ԁF�N(YYYY)
--
    ln_tax_kbn              NUMBER DEFAULT 1; -- �ŋ敪����\�J�E���g    
-- 2019/08/30 Ver1.22 Mod End
--
-- Del Start 1.20
--- lv_postal_code      xxcmn_locations2_v.zip%TYPE;           -- �X�֔ԍ�
--- lv_address          xxcmn_locations2_v.address_line1%TYPE; -- �Z��
--- lv_tel_num          xxcmn_locations2_v.phone%TYPE;         -- �d�b�ԍ�
--- lv_fax_num          xxcmn_locations2_v.fax%TYPE;           -- FAX�ԍ�
--- lv_dept_formal_name xxcmn_locations2_v.location_name%TYPE; -- ����������
-- Del End 1.20
--
    ln_quantity                   NUMBER; -- ����
    ln_purchase_amount            NUMBER; -- �d�����z
    ln_purchase_amount_tax        NUMBER; -- �����:�d�����z
    ln_pure_purchase_amount       NUMBER; -- ���d�����z
    ln_cupr_tax                   NUMBER; -- �����:���K���z
    ln_pure_cupr_tax              NUMBER; -- �����K���z
    ln_deduction_amount           NUMBER; -- �������z
    ln_deduction_amount_tax       NUMBER; -- �����:�������z
    ln_pure_deduction_amount      NUMBER; -- ���������z
-- Ver1.25 Add Start
    ln_p_amount_tax_bd_tab        NUMBER; -- �d�������(�ŋ敪����)
    ln_unit_price_rate_tax_bd_tab NUMBER; -- ���K�����(�ŋ敪����)
-- Ver1.25 Add End
--
    lt_xml_idx                NUMBER DEFAULT 0; -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
    lv_errmsg_no_data         VARCHAR2(5000);   -- �f�[�^�Ȃ����b�Z�[�W
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    lv_from_year  := TO_CHAR(ir_param.d_deliver_from,gc_char_yyyy_format);
    lv_from_month := TO_CHAR(ir_param.d_deliver_from,gc_char_mm_format);
    lv_from_date  := TO_CHAR(ir_param.d_deliver_from,gc_char_dd_format);
    lv_to_year    := TO_CHAR(ir_param.d_deliver_to,gc_char_yyyy_format);
-- 2019/08/30 Ver1.22 Mod Start
--    lv_to_year_yy := TO_CHAR(ir_param.d_deliver_to,gc_char_yy_format);
    lv_year_yyyy  := TO_CHAR(ir_param.d_deliver_to,gc_char_yyyy_format);
-- 2019/08/30 Ver1.22 Mod End
    lv_to_month   := TO_CHAR(ir_param.d_deliver_to,gc_char_mm_format);
    lv_to_date    := TO_CHAR(ir_param.d_deliver_to,gc_char_dd_format);
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[�h�c
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_id' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := gv_report_id ;
    -- ���{��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'exec_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- �N
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_name_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- 2019/08/30 Ver1.22 Mod Start
--    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_year_yy ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_year_yyyy ;
-- 2019/08/30 Ver1.22 Mod End
    -- ��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_name_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_month ;
    -- �N�F���ԊJ�n
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_year ;
    -- ���F���ԊJ�n
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_month ;
    -- ���F���ԊJ�n
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'from_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_from_date ;
    -- �N�F���ԏI��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_year' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_year ;
    -- ���F���ԏI��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_month' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_month ;
    -- ���F���ԏI��
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'to_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := lv_to_date ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �����k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    -- �����m�F
    IF (it_data_rec.COUNT = gn_zero) THEN
      -- �O�����b�Z�[�W�o��
      lv_errmsg_no_data := xxcmn_common_pkg.get_msg( gc_application_po
                                                   ,'APP-XXPO-00009' ) ;
--
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_company_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'msg' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := lv_errmsg_no_data;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..it_data_rec.COUNT LOOP
      -- =====================================================
      -- �����R�[�h�u���C�N
      -- =====================================================
      -- �����R�[�h���؂�ւ�����ꍇ
      IF ( NVL( it_data_rec(i).segment1_s, lc_break_null ) <> lv_company_code ) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_company_code <> lc_break_init ) THEN
          ------------------------------
          -- �����҃R�[�h�w�b�_�f�I���^�O
          ------------------------------
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_mediator_code' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- 2019/08/30 Ver1.22 Add Start
          ------------------------------
          -- ���y�[�W
          ------------------------------
          IF (it_data_rec(i-1).break_page_flg = cv_flag_y) THEN
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'break_page' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := '' ;
          END IF;
          ------------------------------
          -- �ŋ敪����\�̏o��
          ------------------------------
          <<tax_kbn_bd_loop>>
          FOR i IN 1..gt_description_tbl.COUNT LOOP
            ------------------------------
            -- �ŋ敪����\�w�b�_�f�J�n�^�O
            ------------------------------
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'g_tax_kbn' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            -- �ŋ敪
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_kbn_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := gt_tax_kbn_bd_1_tab(ln_tax_kbn) ;
            -- �d�����z(�Ŕ�)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_bd_tab(ln_tax_kbn) ,0) ;
            -- �d�������
-- Ver1.25 Add Start
            ln_p_amount_tax_bd_tab := ROUND( NVL(gt_p_amount_bd_tab(ln_tax_kbn) ,0) * gt_tax_rate_tab(ln_tax_kbn) ,0);
-- Ver1.25 Add End
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- Ver1.25 Mod Start
--            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
            ot_xml_data_table(lt_xml_idx).tag_value := ln_p_amount_tax_bd_tab ;
-- Ver1.25 Mod End
            -- ���K���z(�Ŕ�)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
            -- ���K�����
-- Ver1.25 Add Start
            ln_unit_price_rate_tax_bd_tab := ROUND( NVL(gt_unit_price_rate_bd_tab(ln_tax_kbn) ,0) * gt_kousen_tax_rate_tab(ln_tax_kbn) ,0);
-- Ver1.25 Add End
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- Ver1.25 Mod Start
--            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
            ot_xml_data_table(lt_xml_idx).tag_value :=ln_unit_price_rate_tax_bd_tab ;
-- Ver1.25 Mod End
            -- ���ۋ�
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
            -- ���ۋ������
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_u_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
            -- ���v(�Ŕ����z)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_excluded_amount_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_tax_exc_amount_bd_tab(ln_tax_kbn) ,0) ;
            -- ���v(�����)
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax_breakdown' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- Ver1.25 Mod Start
--            ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_ded_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
            ot_xml_data_table(lt_xml_idx).tag_value := ln_p_amount_tax_bd_tab + ln_unit_price_rate_tax_bd_tab ;
-- Ver1.25 Mod End
--
            ------------------------------
            -- �ŋ敪����\�w�b�_�f�I���^�O
            ------------------------------
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/g_tax_kbn' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            -- �o�͉񐔃J�E���g�A�b�v
            ln_tax_kbn := ln_tax_kbn + 1;
          END LOOP tax_kbn_bd_loop;
-- 2019/08/30 Ver1.22 Add End
          ------------------------------
          -- �����R�[�h�w�b�_�f�I���^�O
          ------------------------------
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/g_company_code' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �����f�J�n�^�O�o��
        -- -----------------------------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_company_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- 2019/08/30 Ver1.22 Del Start
---- add start 1.10
--        -- ����於�̕������擾
--        ln_vendor_name_len := LENGTH(it_data_rec(i).vendor_name);
---- add end 1.10
-- 2019/08/30 Ver1.22 Del End
        -- ����於�P
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- 2019/08/30 Ver1.22 Mod Start
---- mod start 1.10
----        ot_xml_data_table(lt_xml_idx).tag_value :=
----          SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_15) ;
--        IF (ln_vendor_name_len <= gn_20) THEN
--          -- �h�̂�t����
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_20) || gv_keishou ;
--        ELSE
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_20) ;
--        END IF;
---- mod end 1.10
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).vendor_name,gn_one,gn_15) ;
-- 2019/08/30 Ver1.22 Mod End
        -- ����於�Q
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_name2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- 2019/08/30 Ver1.22 Mod Start
---- mod start 1.10
----        ot_xml_data_table(lt_xml_idx).tag_value :=
----          SUBSTR(it_data_rec(i).vendor_name,gn_16,gn_30) ;
--        IF (ln_vendor_name_len >= gn_21) THEN
--          -- �h�̂�t����
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_21,gn_40) || gv_keishou ;
--        ELSE
--          ot_xml_data_table(lt_xml_idx).tag_value :=
--            SUBSTR(it_data_rec(i).vendor_name,gn_21,gn_40) ;
--        END IF;
---- mod end 1.10
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).vendor_name,gn_16,gn_30) ;
-- 2019/08/30 Ver1.22 Mod End
-- Ver1.25 Add Start
        -- �o�^�ԍ�
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'invoice_t_no' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).invoice_t_no ;
-- Ver1.25 Add End
        -- �M�ЃR�[�h
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'your_company_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).segment1_s ;
        -- �X�֔ԍ�
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_postal_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).zip ;
        -- �����Z���P
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_address' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).address_line1,gn_one,gn_15) ;
        -- �����Z���Q
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_address2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).address_line2,gn_one,gn_15) ;
        -- �����TEL
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_telephone_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).phone,gn_one,gn_15) ;
        -- �����FAX
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'business_partner_fax_number' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTR(it_data_rec(i).fax,gn_one,gn_15) ;
--
        -- �������̎擾
-- Del Start 1.20
------- xxcmn_common_pkg.get_dept_info(
-------   iv_dept_cd          => it_data_rec(i).attribute10  -- �����R�[�h(���Ə�CD)
-------  ,id_appl_date        => ir_param.d_deliver_from -- ���
-------  ,ov_postal_code      => lv_postal_code      -- �X�֔ԍ�
-------  ,ov_address          => lv_address          -- �Z��
-------  ,ov_tel_num          => lv_tel_num          -- �d�b�ԍ�
-------  ,ov_fax_num          => lv_fax_num          -- FAX�ԍ�
-------  ,ov_dept_formal_name => lv_dept_formal_name -- ����������
-------  ,ov_errbuf           => lv_errbuf
-------  ,ov_retcode          => lv_retcode
-------  ,ov_errmsg           => lv_errmsg);
-- Del End 1.20
--
-- 2019/08/30 Ver1.22 Mod Start
--        -- ���t���Z��
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_address' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_address,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL;
---- Mod End 1.20
--        -- ���t��TEL
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_telephone_number' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_tel_num,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL ;
---- Mod End 1.20
--        -- ���t��FAX
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_fax_number' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_fax_num,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL;
---- Mod End 1.20
--        -- ���t������
--        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
--        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_dept_name' ;
--        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
---- Mod Start 1.20
--------- ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(lv_dept_formal_name,gn_one,gn_15) ;
--        ot_xml_data_table(lt_xml_idx).tag_value := NULL;
---- Mod End 1.20
        ------------------------------
        -- ��������
        ------------------------------
        -- �����於
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_dept_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := gv_from_dept_name;
        -- ������X�֔ԍ�
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_postal_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := gv_from_postal_code;
        -- ������Z��
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'from_address' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := gv_from_address;
--
        ------------------------------
        -- �U������
        ------------------------------
        -- ���Z�@�֖�
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_name ;
        -- �x�X��
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_brach_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_branch_name ;
        -- �a���敪
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_type' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_account_type ;
        -- ����No.
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_num' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).bank_account_num ;
        -- �������`1
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_name_alt1' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).bank_account_name_alt,gn_one,gn_75) ;
        -- �������`2
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'bank_account_name_alt2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := SUBSTR(it_data_rec(i).bank_account_name_alt,gn_76,gn_150) ;
--
-- 2019/08/30 Ver1.22 Mod End
        ------------------------------
        -- �����҃w�b�_
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_mediator_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_company_code  := NVL( it_data_rec(i).segment1_s, lc_break_null )  ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      -- ���׃N���A
      ln_quantity              := 0; -- ����
      ln_purchase_amount       := 0; -- �d�����z
      ln_purchase_amount_tax   := 0; -- �����:�d�����z
      ln_pure_purchase_amount  := 0; -- ���d�����z
      ln_cupr_tax              := 0; -- �����:���K���z
      ln_pure_cupr_tax         := 0; -- �����K���z
      ln_deduction_amount      := 0; -- �������z
      ln_deduction_amount_tax  := 0; -- �����:�������z
      ln_pure_deduction_amount := 0; -- ���������z
      -- -----------------------------------------------------
      -- ����
      -- -----------------------------------------------------
      -- �����҃w�b�_
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      -- �����҃R�[�h
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).segment1_a;
      -- �����Җ�
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_one,gn_10) ;
      -- �����Җ��Q
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name2' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_11,gn_20) ;
      -- �����Җ��R
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'mediator_name3' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value :=
        SUBSTR(it_data_rec(i).vendor_full_name,gn_21,gn_30) ;
      -- ����
      ln_quantity := ROUND(it_data_rec(i).quantity,3);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'quantity' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_quantity);
      -- �d�����z
-- 2009/08/10 v1.18 T.Yoshimoto Mod Start �{��#1596(�l�̌ܓ���)
-- 2008/11/04 v1.11 Y.Yamamoto update start
      ln_purchase_amount := ROUND(it_data_rec(i).purchase_amount);
--      ln_purchase_amount := TRUNC(it_data_rec(i).purchase_amount);
-- 2008/11/04 v1.11 Y.Yamamoto update end
-- 2009/08/10 v1.18 T.Yoshimoto Mod End �{��#1596(�l�̌ܓ���)
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_purchase_amount);
      -- �����:�d�����z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
--      ln_purchase_amount_tax := ROUND(ln_purchase_amount * gn_tax);
      ln_purchase_amount_tax := it_data_rec(i).purchase_amount_tax;
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_purchase_amount_tax);
      -- ���d�����z
      ln_pure_purchase_amount := ln_purchase_amount + ln_purchase_amount_tax;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_purchase_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_purchase_amount);
-- 2019/08/30 Ver1.22 Add Start
      -- �d���ŋ敪
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_tax_kbn' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).purchase_tax_kbn;
-- 2019/08/30 Ver1.22 Add End
      -- ���K
      IF (it_data_rec(i).attribute5 IS NOT NULL) THEN
        -- ���K���z
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).attribute5;
        -- �����:���K���z
-- 2009/01/08 v1.13 N.Yoshida Mod Start �{��#970
--        ln_cupr_tax := ROUND(it_data_rec(i).attribute5 * gn_tax);
        ln_cupr_tax := it_data_rec(i).attribute5_tax;
-- 2009/01/08 v1.13 N.Yoshida Mod End �{��#970
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_cupr_tax);
        -- �����K���z
        ln_pure_cupr_tax := it_data_rec(i).attribute5 + ln_cupr_tax;
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_commission_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_cupr_tax);
-- 2019/08/30 Ver1.22 Add Start
        -- ���K�ŋ敪
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_tax_kbn' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(i).comm_price_tax_kbn;
-- 2019/08/30 Ver1.22 Add End
      END IF;
      -- ����
      IF (it_data_rec(i).attribute8 IS NOT NULL) THEN
        -- ���ۋ��z
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(it_data_rec(i).attribute8);
        -- ���ۋ��z(3�i��)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(it_data_rec(i).attribute8);
      END IF;
      -- �������z
      ln_deduction_amount :=
        ln_purchase_amount - NVL(it_data_rec(i).attribute5,0) - NVL(it_data_rec(i).attribute8,0);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_deduction_amount);
      -- �����:�������z
      ln_deduction_amount_tax := ln_purchase_amount_tax - ln_cupr_tax;
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_deduction_amount_tax);
      -- ���������z
      ln_pure_deduction_amount :=
        ln_pure_purchase_amount - ln_pure_cupr_tax - NVL(it_data_rec(i).attribute8,0);
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'pure_deduction_amount' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
      ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR(ln_pure_deduction_amount);
      -- �����҃w�b�_
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/g_mediator_code' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �����҃R�[�h�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_mediator_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
-- 2019/08/30 Ver1.22 Add Start
    -- �����m�F
    IF (it_data_rec.COUNT <> gn_zero) THEN
      ------------------------------
      -- ���y�[�W
      ------------------------------
      IF (gv_break_page_flg = cv_flag_y) THEN
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'break_page' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := '' ;
      END IF;
      ------------------------------
      -- �ŋ敪����\�̏o��
      ------------------------------
      <<tax_kbn_bd_loop>>
      FOR i IN 1..gt_description_tbl.COUNT LOOP
        ------------------------------
        -- �ŋ敪����\�w�b�_�f�J�n�^�O
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_tax_kbn' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- �ŋ敪
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_kbn_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
--        ot_xml_data_table(lt_xml_idx).tag_value := gt_tax_kbn_bd_tab(ln_tax_kbn) ;
        ot_xml_data_table(lt_xml_idx).tag_value := gt_tax_kbn_bd_1_tab(ln_tax_kbn) ;
        -- �d�����z(�Ŕ�)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_bd_tab(ln_tax_kbn) ,0) ;
        -- �d�������
-- Ver1.25 Add Start
        ln_p_amount_tax_bd_tab := ROUND( NVL(gt_p_amount_bd_tab(ln_tax_kbn) ,0) * gt_tax_rate_tab(ln_tax_kbn) ,0);
-- Ver1.25 Add End
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'purchase_amount_tax_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- Ver1.25 Mod Start
--        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_p_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
        ot_xml_data_table(lt_xml_idx).tag_value := ln_p_amount_tax_bd_tab ;
-- Ver1.25 Mod End
        -- ���K���z(�Ŕ�)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
        -- ���K�����
-- Ver1.25 Add Start
        ln_unit_price_rate_tax_bd_tab := ROUND( NVL(gt_unit_price_rate_bd_tab(ln_tax_kbn) ,0) * gt_kousen_tax_rate_tab(ln_tax_kbn) ,0);
-- Ver1.25 Add End
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'commission_unit_price_rate_tax_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- Ver1.25 Mod Start
--        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_unit_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
        ot_xml_data_table(lt_xml_idx).tag_value := ln_unit_price_rate_tax_bd_tab ;
-- Ver1.25 Mod End
        -- ���ۋ�
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_unit_price_rate_bd_tab(ln_tax_kbn) ,0) ;
        -- ���ۋ������
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'levy_unit_price_rate_2_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_l_u_price_rate_tax_bd_tab(ln_tax_kbn) ,0) ;
        -- ���v(�Ŕ����z)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'tax_excluded_amount_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_tax_exc_amount_bd_tab(ln_tax_kbn) ,0) ;
        -- ���v(�����)
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'deduction_amount_tax_breakdown' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
-- Ver1.25 Mod Start
--        ot_xml_data_table(lt_xml_idx).tag_value := NVL(gt_ded_amount_tax_bd_tab(ln_tax_kbn) ,0) ;
        ot_xml_data_table(lt_xml_idx).tag_value := ln_p_amount_tax_bd_tab + ln_unit_price_rate_tax_bd_tab ;
-- Ver1.25 Mod End
--
        ------------------------------
        -- �ŋ敪����\�w�b�_�f�I���^�O
        ------------------------------
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := '/g_tax_kbn' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
        -- �o�͉񐔃J�E���g�A�b�v
        ln_tax_kbn := ln_tax_kbn + 1;
      END LOOP tax_kbn_bd_loop;
    END IF;
-- 2019/08/30 Ver1.22 Add End
    ------------------------------
    -- �����R�[�h�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/g_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����k�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_company_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : �p�����[�^�̎擾
   ***********************************************************************************/
  PROCEDURE prc_set_param(
      ov_errbuf             OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_deliver_from       IN  VARCHAR2       -- �[����FROM
     ,iv_deliver_to         IN  VARCHAR2       -- �[����TO
     ,iv_vendor_code1       IN  VARCHAR2       -- �����P
     ,iv_vendor_code2       IN  VARCHAR2       -- �����Q
     ,iv_vendor_code3       IN  VARCHAR2       -- �����R
     ,iv_vendor_code4       IN  VARCHAR2       -- �����S
     ,iv_vendor_code5       IN  VARCHAR2       -- �����T
     ,iv_assen_vendor_code1 IN  VARCHAR2       -- �����҂P
     ,iv_assen_vendor_code2 IN  VARCHAR2       -- �����҂Q
     ,iv_assen_vendor_code3 IN  VARCHAR2       -- �����҂R
     ,iv_assen_vendor_code4 IN  VARCHAR2       -- �����҂S
     ,iv_assen_vendor_code5 IN  VARCHAR2       -- �����҂T
     ,iv_dept_code1         IN  VARCHAR2       -- �S�������P
     ,iv_dept_code2         IN  VARCHAR2       -- �S�������Q
     ,iv_dept_code3         IN  VARCHAR2       -- �S�������R
     ,iv_dept_code4         IN  VARCHAR2       -- �S�������S
     ,iv_dept_code5         IN  VARCHAR2       -- �S�������T
     ,iv_security_flg       IN  VARCHAR2       -- �Z�L�����e�B�敪
     ,or_param_rec          OUT rec_param_data -- ���̓p�����[�^�Q
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_set_param' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_vendor_code       NUMBER DEFAULT 0; -- �����
    ln_assen_vendor_code NUMBER DEFAULT 0; -- ������
    ln_dept_code         NUMBER DEFAULT 0; -- �S������
--
    -- *** ���[�J���E��O���� ***
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �[����(FROM)���t�^
    or_param_rec.d_deliver_from := FND_DATE.STRING_TO_DATE(iv_deliver_from,gc_char_dt_format);
    -- �[����(TO)  ���t�^
    or_param_rec.d_deliver_to   := FND_DATE.STRING_TO_DATE(iv_deliver_to,gc_char_dt_format);
    -- �[����(FROM)
    or_param_rec.deliver_from   := TO_CHAR(or_param_rec.d_deliver_from ,gc_char_d_format);
    -- �[����(TO)
    or_param_rec.deliver_to     := TO_CHAR(or_param_rec.d_deliver_to ,gc_char_d_format);
    -- �Z�L�����e�B�敪
    or_param_rec.security_flg   := iv_security_flg;
--
    -- �����P
    IF (TRIM(iv_vendor_code1) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- �����Q
    IF (TRIM(iv_vendor_code2) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- �����R
    IF (TRIM(iv_vendor_code3) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- �����S
    IF (TRIM(iv_vendor_code4) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- �����T
    IF (TRIM(iv_vendor_code5) IS NOT NULL) THEN
      ln_vendor_code := or_param_rec.vendor_code.COUNT + 1;
      or_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- �����҂P
    IF (TRIM(iv_assen_vendor_code1) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code1;
    END IF;
    -- �����҂Q
    IF (TRIM(iv_assen_vendor_code2) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code2;
    END IF;
    -- �����҂R
    IF (TRIM(iv_assen_vendor_code3) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code3;
    END IF;
    -- �����҂S
    IF (TRIM(iv_assen_vendor_code4) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code4;
    END IF;
    -- �����҂T
    IF (TRIM(iv_assen_vendor_code5) IS NOT NULL) THEN
      ln_assen_vendor_code := or_param_rec.assen_vendor_code.COUNT + 1;
      or_param_rec.assen_vendor_code(ln_assen_vendor_code) := iv_assen_vendor_code5;
    END IF;
--
    -- �S�������P
    IF (TRIM(iv_dept_code1) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code1;
    END IF;
    -- �S�������Q
    IF (TRIM(iv_dept_code2) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code2;
    END IF;
    -- �S�������R
    IF (TRIM(iv_dept_code3) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code3;
    END IF;
    -- �S�������S
    IF (TRIM(iv_dept_code4) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code4;
    END IF;
    -- �S�������T
    IF (TRIM(iv_dept_code5) IS NOT NULL) THEN
      ln_dept_code := or_param_rec.dept_code.COUNT + 1;
      or_param_rec.dept_code(ln_dept_code) := iv_dept_code5;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_set_param ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf             OUT VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_deliver_from       IN  VARCHAR2        -- �[����FROM
     ,iv_deliver_to         IN  VARCHAR2        -- �[����TO
     ,iv_vendor_code1       IN  VARCHAR2        -- �����P
     ,iv_vendor_code2       IN  VARCHAR2        -- �����Q
     ,iv_vendor_code3       IN  VARCHAR2        -- �����R
     ,iv_vendor_code4       IN  VARCHAR2        -- �����S
     ,iv_vendor_code5       IN  VARCHAR2        -- �����T
     ,iv_assen_vendor_code1 IN  VARCHAR2        -- �����҂P
     ,iv_assen_vendor_code2 IN  VARCHAR2        -- �����҂Q
     ,iv_assen_vendor_code3 IN  VARCHAR2        -- �����҂R
     ,iv_assen_vendor_code4 IN  VARCHAR2        -- �����҂S
     ,iv_assen_vendor_code5 IN  VARCHAR2        -- �����҂T
     ,iv_dept_code1         IN  VARCHAR2        -- �S�������P
     ,iv_dept_code2         IN  VARCHAR2        -- �S�������Q
     ,iv_dept_code3         IN  VARCHAR2        -- �S�������R
     ,iv_dept_code4         IN  VARCHAR2        -- �S�������S
     ,iv_dept_code5         IN  VARCHAR2        -- �S�������T
     ,iv_security_flg       IN  VARCHAR2        -- �Z�L�����e�B�敪
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec         rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string        VARCHAR2(32000) ;
    ln_retcode           NUMBER ;
--
    ------------------------------
    -- �w�l�k�p
    ------------------------------
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
    lt_main_data_before       tab_data_type_dtl2; -- �擾���R�[�h�\(�ҏW�O)
-- 2009/05/26 v1.15 T.Yoshimoto Add End
    lt_main_data              tab_data_type_dtl; -- �擾���R�[�h�\
    lt_xml_data_table         XML_DATA;          -- �w�l�k�f�[�^�^�O�\
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �p�����[�^�i�[
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_deliver_from       => iv_deliver_from       -- �[����FROM
       ,iv_deliver_to         => iv_deliver_to         -- �[����TO
       ,iv_vendor_code1       => iv_vendor_code1       -- �����P
       ,iv_vendor_code2       => iv_vendor_code2       -- �����Q
       ,iv_vendor_code3       => iv_vendor_code3       -- �����R
       ,iv_vendor_code4       => iv_vendor_code4       -- �����S
       ,iv_vendor_code5       => iv_vendor_code5       -- �����T
       ,iv_assen_vendor_code1 => iv_assen_vendor_code1 -- �����҂P
       ,iv_assen_vendor_code2 => iv_assen_vendor_code2 -- �����҂Q
       ,iv_assen_vendor_code3 => iv_assen_vendor_code3 -- �����҂R
       ,iv_assen_vendor_code4 => iv_assen_vendor_code4 -- �����҂S
       ,iv_assen_vendor_code5 => iv_assen_vendor_code5 -- �����҂T
       ,iv_dept_code1         => iv_dept_code1         -- �S�������P
       ,iv_dept_code2         => iv_dept_code2         -- �S�������Q
       ,iv_dept_code3         => iv_dept_code3         -- �S�������R
       ,iv_dept_code4         => iv_dept_code4         -- �S�������S
       ,iv_dept_code5         => iv_dept_code5         -- �S�������T
       ,iv_security_flg       => iv_security_flg       -- �Z�L�����e�B�敪
       ,or_param_rec          => lr_param_rec          -- ���̓p�����[�^�Q
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
        ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param      => lr_param_rec   -- ���̓p�����[�^�Q
-- 2009/05/26 v1.15 T.Yoshimoto Mod Start
--       ,ot_data_rec   => lt_main_data   -- �擾���R�[�h�Q
       ,ot_data_rec   => lt_main_data_before   -- �擾���R�[�h�Q
-- 2009/05/26 v1.15 T.Yoshimoto Mod End
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/22 v1.17 T.Yoshimoto Add Start �{�ԏ�Q#1516(��)��v1.15�Ή����̏�Q
    IF ( lt_main_data_before.COUNT > 0 ) THEN
-- 2009/06/22 v1.17 T.Yoshimoto Add End �{�ԏ�Q#1516(��)��v1.15�Ή����̏�Q
-- 2009/05/26 v1.15 T.Yoshimoto Add Start
      -- =====================================================
      -- �擾���R�[�h��ҏW����
      -- =====================================================
      prc_edit_data(
          ov_errbuf     => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode    => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg     => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ,it_data_rec   => lt_main_data_before   -- ���̓p�����[�^�Q
         ,ot_data_rec   => lt_main_data   -- �擾���R�[�h�Q
      ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- 2009/05/26 v1.15 T.Yoshimoto Add End
-- 2009/06/22 v1.17 T.Yoshimoto Add Start �{�ԏ�Q#1516(��)��v1.15�Ή����̏�Q
    END IF;
-- 2009/06/22 v1.17 T.Yoshimoto Add End �{�ԏ�Q#1516(��)��v1.15�Ή����̏�Q
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,it_data_rec       => lt_main_data       -- �擾���R�[�h�Q
       ,ot_xml_data_table => lt_xml_data_table  -- XML�f�[�^
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML�o�͏���
    -- =====================================================
    prc_out_xml(
        ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,ir_param          => lr_param_rec      -- ���̓p�����[�^�Q
       ,it_xml_data_table => lt_xml_data_table -- �擾���R�[�h�Q
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF (lt_main_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_deliver_from       IN     VARCHAR2         -- �[����FROM
     ,iv_deliver_to         IN     VARCHAR2         -- �[����TO
     ,iv_vendor_code1       IN     VARCHAR2         -- �����P
     ,iv_vendor_code2       IN     VARCHAR2         -- �����Q
     ,iv_vendor_code3       IN     VARCHAR2         -- �����R
     ,iv_vendor_code4       IN     VARCHAR2         -- �����S
     ,iv_vendor_code5       IN     VARCHAR2         -- �����T
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- �����҂P
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- �����҂Q
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- �����҂R
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- �����҂S
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- �����҂T
     ,iv_dept_code1         IN     VARCHAR2         -- �S�������P
     ,iv_dept_code2         IN     VARCHAR2         -- �S�������Q
     ,iv_dept_code3         IN     VARCHAR2         -- �S�������R
     ,iv_dept_code4         IN     VARCHAR2         -- �S�������S
     ,iv_dept_code5         IN     VARCHAR2         -- �S�������T
     ,iv_security_flg       IN     VARCHAR2         -- �Z�L�����e�B�敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_deliver_from       => iv_deliver_from       -- �[����FROM
       ,iv_deliver_to         => iv_deliver_to         -- �[����TO
       ,iv_vendor_code1       => iv_vendor_code1       -- �����P
       ,iv_vendor_code2       => iv_vendor_code2       -- �����Q
       ,iv_vendor_code3       => iv_vendor_code3       -- �����R
       ,iv_vendor_code4       => iv_vendor_code4       -- �����S
       ,iv_vendor_code5       => iv_vendor_code5       -- �����T
       ,iv_assen_vendor_code1 => iv_assen_vendor_code1 -- �����҂P
       ,iv_assen_vendor_code2 => iv_assen_vendor_code2 -- �����҂Q
       ,iv_assen_vendor_code3 => iv_assen_vendor_code3 -- �����҂R
       ,iv_assen_vendor_code4 => iv_assen_vendor_code4 -- �����҂S
       ,iv_assen_vendor_code5 => iv_assen_vendor_code5 -- �����҂T
       ,iv_dept_code1         => iv_dept_code1         -- �S�������P
       ,iv_dept_code2         => iv_dept_code2         -- �S�������Q
       ,iv_dept_code3         => iv_dept_code3         -- �S�������R
       ,iv_dept_code4         => iv_dept_code4         -- �S�������S
       ,iv_dept_code5         => iv_dept_code5         -- �S�������T
       ,iv_security_flg       => iv_security_flg       -- �Z�L�����e�B�敪
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo360005c ;

/
