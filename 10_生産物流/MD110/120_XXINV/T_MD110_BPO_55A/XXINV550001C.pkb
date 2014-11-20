CREATE OR REPLACE PACKAGE BODY xxinv550001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550001c(body)
 * Description      : �݌Ɂi���[�j
 * MD.050/070       : �݌Ɂi���[�jIssue1.0  (T_MD050_BPO_550)
 *                    �󕥎c�����X�g        (T_MD070_BPO_55A)
 * Version          : 1.14
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XML�f�[�^�ϊ�
 *  insert_xml_plsql_table    XML�f�[�^�i�[
 *  prc_check_param_info      �p�����[�^�`�F�b�N(A-1)
 *  prc_call_xxinv550004c     �I���X�i�b�v�V���b�g�쐬�v���O�����ďo(A-2)
 *  prc_get_report_data       ���׃f�[�^�擾(A-3)
 *  prc_create_xml_data       �w�l�k�f�[�^�쐬(A-4)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/02/01    1.0   Yasuhisa Yamamoto  �V�K�쐬
 *  2008/05/07    1.1   Yasuhisa Yamamoto  �ύX�v���Ή�(Seq83)
 *  2008/05/09    1.2   Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(���o�f�[�^�L���كf�[�^���Ή�)
 *  2008/05/09    1.3   Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(�I�����ʃe�[�u��LotID NULL�Ή�)
 *  2008/05/20    1.4   Yusuke   Tabata    �����ύX�v��(Seq95)���t�^�p�����[�^�^�ϊ��Ή�
 *  2008/05/20    1.5   Kazuo Kumamoto     �����e�X�g��Q�Ή�(�i�ڌ����}�X�^���o�^�Ή�)
 *  2008/05/20    1.6   Kazuo Kumamoto     �����e�X�g��Q�Ή�(�I���X�i�b�v�V���b�g��O�L���b�`)
 *  2008/05/21    1.7   Kazuo Kumamoto     �����e�X�g��Q�Ή�(���v����ALL0�͏��O)
 *  2008/05/21    1.8   Kazuo Kumamoto     �����e�X�g��Q�Ή�(���I�����݌ɐ��̎Z�o�s�)
 *  2008/05/26    1.9   Kazuo Kumamoto     �����e�X�g��Q�Ή�(�P�ʏo�͂̃Y��)
 *  2008/05/26    1.10  Kazuo Kumamoto     �����e�X�g��Q�Ή�(�i�ڌv�o�͏����ύX)
 *  2008/06/07    1.11  Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(���o�f�[�^�s���Ή�)
 *  2008/06/20    1.12  Kazuo Kumamoto     �V�X�e���e�X�g��Q�Ή�(�p�����[�^�����w��̕s�)
 *  2008/07/02    1.13  Satoshi Yunba      �֑������Ή�
 *  2008/07/08    1.14  Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(ADJI����ID��NULL�Ή��A���o�ɐ���0�̏o�͑Ή�)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal             CONSTANT VARCHAR2(1)   := '0' ;
  gv_status_warn               CONSTANT VARCHAR2(1)   := '1' ;
  gv_status_error              CONSTANT VARCHAR2(1)   := '2' ;
  gv_msg_part                  CONSTANT VARCHAR2(3)   := ' : ' ;
  gv_msg_cont                  CONSTANT VARCHAR2(3)   := '.';
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
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxinv550001c' ;         -- �p�b�P�[�W��
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXINV550001T';          -- ���[ID
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;                    -- �o�̓^�O�^�C�v�iT�F�^�O�j
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;                    -- �o�̓^�O�^�C�v�iD�F�f�[�^�j
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;                    -- �o�̓^�C�v�iC�FChar�j
  gc_first_day                 CONSTANT VARCHAR2(2)   := '01' ;                   -- ������
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code             CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_completed_ind_1           CONSTANT NUMBER        := 1 ;
  gc_enabled_flag_y            CONSTANT VARCHAR2(1)   := 'Y' ;
  gc_use_div_invent_y          CONSTANT VARCHAR2(1)   := 'Y' ;
  gc_inactive_ind_mukou        CONSTANT NUMBER        := 1 ;
  gc_cat_item_class_shohin     CONSTANT VARCHAR2(8)   := '���i�敪';              -- �J�e�S���Z�b�g���i���i�敪�j
  gc_cat_item_class_hinmoku    CONSTANT VARCHAR2(8)   := '�i�ڋ敪';              -- �J�e�S���Z�b�g���i�i�ڋ敪�j
  gc_rcv_pay_div_uke           CONSTANT VARCHAR2(2)   := '1';                     -- �󕥋敪�i����j
  gc_rcv_pay_div_harai         CONSTANT VARCHAR2(2)   := '-1';                    -- �󕥋敪�i���o�j
  gc_item_div_genryo           CONSTANT VARCHAR2(1)   := '1';                     -- �i�ڋ敪�i�����j
  gc_item_div_sizai            CONSTANT VARCHAR2(1)   := '2';                     -- �i�ڋ敪�i���ށj
  gc_item_div_hanseihin        CONSTANT VARCHAR2(1)   := '4';                     -- �i�ڋ敪�i�����i�j
  gc_item_div_seihin           CONSTANT VARCHAR2(1)   := '5';                     -- �i�ڋ敪�i���i�j
  gc_um_class_honsu            CONSTANT VARCHAR2(1)   := '0';                     -- �P�ʋ敪�i�{���j
  gc_um_class_case             CONSTANT VARCHAR2(1)   := '1';                     -- �P�ʋ敪�i�P�[�X�j
  gc_cost_manage_code_hyozyun  CONSTANT VARCHAR2(1)   := '1';                     -- �����Ǘ��敪�i�W���j
  gc_cost_manage_code_jissei   CONSTANT VARCHAR2(1)   := '0';                     -- �����Ǘ��敪�i�����j
  gc_output_ctl_all            CONSTANT VARCHAR2(1)   := '0';                     -- ���ً敪�iALL�j
  gc_output_ctl_sel            CONSTANT VARCHAR2(1)   := '1';                     -- ���ً敪�i���ق�������́j
  gc_employee_div_out          CONSTANT VARCHAR2(1)   := '2';                     -- �]�ƈ��敪�i�O���j
  gc_reason_div_1              CONSTANT VARCHAR2(1)   := '1';                     -- �󕥋敪�}�X�^���ʁ{�l
  gc_reason_div_0              CONSTANT VARCHAR2(1)   := '0';                     -- �󕥋敪�}�X�^���ʁ|�l
  gc_lot_ctl_1                 CONSTANT NUMBER        := 1;                       -- ���b�g�Ǘ��敪�i�L�j
  gc_xvst_txns_type_1          CONSTANT VARCHAR2(1)   := '1';                     -- �����^�C�v�i�����݌Ɂj
--
  gc_doc_type_xfer             CONSTANT VARCHAR2(4)   := 'XFER' ;                 -- �݌Ƀg���������^�C�v�iXFER�j
  gc_doc_type_omso             CONSTANT VARCHAR2(4)   := 'OMSO' ;                 -- �݌Ƀg���������^�C�v�iOMSO�j
  gc_doc_type_prod             CONSTANT VARCHAR2(4)   := 'PROD' ;                 -- �݌Ƀg���������^�C�v�iPROD�j
  gc_doc_type_porc             CONSTANT VARCHAR2(4)   := 'PORC' ;                 -- �݌Ƀg���������^�C�v�iPORC�j
  gc_doc_type_adji             CONSTANT VARCHAR2(4)   := 'ADJI' ;                 -- �݌Ƀg���������^�C�v�iADJI�j
  gc_doc_type_trni             CONSTANT VARCHAR2(4)   := 'TRNI' ;                 -- �݌Ƀg���������^�C�v�iTRNI�j
  gc_src_doc_rma               CONSTANT VARCHAR2(3)   := 'RMA' ;                  -- �݌Ƀg�����\�[�X�����iRMA�j
  gc_reason_adji_xrart         CONSTANT VARCHAR2(4)   := 'X201' ;                 -- �󕥕ԕi����   �d����ԕiX201
  gc_reason_adji_xnpt          CONSTANT VARCHAR2(4)   := 'X988' ;                 -- ���t����       �l�����X988
  gc_reason_adji_xvst          CONSTANT VARCHAR2(4)   := 'X977' ;                 -- �O���o�������� �����݌�X977
  gc_reason_adji_xmril         CONSTANT VARCHAR2(4)   := 'X123' ;                 -- �ړ�����       �ړ����ђ���X123
--
  -- �v���t�@�C��
  gc_cost_div                  CONSTANT VARCHAR2(14)  := 'XXCMN_COST_DIV';
  gc_cost_whse_code            CONSTANT VARCHAR2(26)  := 'XXCMN_COST_PRICE_WHSE_CODE';
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;                -- �A�v���P�[�V�����iXXCMN�j
  gc_application_inv           CONSTANT VARCHAR2(5)   := 'XXINV' ;                -- �A�v���P�[�V�����iXXINV�j
  gc_xxinv_10111               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10111' ;      -- �i�ڃ`�F�b�N�G���[
  gc_xxinv_10112               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10112' ;      -- �q�Ƀ`�F�b�N�G���[
  gc_xxinv_10113               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10113' ;      -- �u���b�N�`�F�b�N�G���[
  gc_xxinv_10114               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10114' ;      -- �q�ɊǗ������`�F�b�N�G���[
  gc_xxinv_10115               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10115' ;      -- ���t�^�G���[
  gc_xxinv_10116               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10116' ;      -- �������G���[
  gc_xxinv_10117               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10117' ;      -- �I���X�i�b�v�V���b�g�쐬�G���[
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;      -- ����0���p���b�Z�[�W
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_ym_format            CONSTANT VARCHAR2(6)   := 'YYYYMM' ;
  gc_char_ym_out_format        CONSTANT VARCHAR2(16)  := 'YYYY"�N"MM"���x"' ;
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      iv_date_ym               VARCHAR2(6)                                        -- 01 : �Ώ۔N��
     ,iv_whse_dept1            mtl_item_locations.attribute3%TYPE                 -- 02 : �q�ɊǗ�����1
     ,iv_whse_dept2            mtl_item_locations.attribute3%TYPE                 -- 03 : �q�ɊǗ�����2
     ,iv_whse_dept3            mtl_item_locations.attribute3%TYPE                 -- 04 : �q�ɊǗ�����3
     ,iv_whse_code1            ic_whse_mst.whse_code%TYPE                         -- 05 : �q�ɃR�[�h1
     ,iv_whse_code2            ic_whse_mst.whse_code%TYPE                         -- 06 : �q�ɃR�[�h2
     ,iv_whse_code3            ic_whse_mst.whse_code%TYPE                         -- 07 : �q�ɃR�[�h3
     ,iv_block_code1           fnd_lookup_values.lookup_code%TYPE                 -- 08 : �u���b�N1
     ,iv_block_code2           fnd_lookup_values.lookup_code%TYPE                 -- 09 : �u���b�N2
     ,iv_block_code3           fnd_lookup_values.lookup_code%TYPE                 -- 10 : �u���b�N3
     ,iv_item_class            mtl_categories_b.segment1%TYPE                     -- 11 : ���i�敪
     ,iv_um_class              fnd_lookup_values.lookup_code%TYPE                 -- 12 : �P�ʋ敪
     ,iv_item_div              mtl_categories_b.segment1%TYPE                     -- 13 : �i�ڋ敪
     ,iv_item_no1              ic_item_mst_b.item_no%TYPE                         -- 14 : �i�ڃR�[�h1
     ,iv_item_no2              ic_item_mst_b.item_no%TYPE                         -- 15 : �i�ڃR�[�h2
     ,iv_item_no3              ic_item_mst_b.item_no%TYPE                         -- 16 : �i�ڃR�[�h3
     ,iv_create_date1          VARCHAR2(10)                                       -- 17 : �����N����1
     ,iv_create_date2          VARCHAR2(10)                                       -- 18 : �����N����2
     ,iv_create_date3          VARCHAR2(10)                                       -- 19 : �����N����3
     ,iv_lot_no1               ic_lots_mst.lot_no%TYPE                            -- 20 : ���b�gNo1
     ,iv_lot_no2               ic_lots_mst.lot_no%TYPE                            -- 21 : ���b�gNo2
     ,iv_lot_no3               ic_lots_mst.lot_no%TYPE                            -- 22 : ���b�gNo3
     ,iv_output_ctl            fnd_lookup_values.lookup_code%TYPE                 -- 23 : ���كf�[�^�敪
    ) ;
--
  -- �󕥎c�����X�g�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
     whse_code                 mtl_item_locations.segment1%TYPE                   -- �q�ɃR�[�h
    ,item_id                   ic_item_mst_b.item_id%TYPE                         -- �i��ID
    ,item_no                   ic_item_mst_b.item_no%TYPE                         -- �i�ڃR�[�h
    ,lot_no                    ic_lots_mst.lot_no%TYPE                            -- ���b�gNo
    ,lot_id                    ic_lots_mst.lot_id%TYPE                            -- ���b�gid
    ,stock_quantity            NUMBER                                             -- ������ʁi���ɐ��j
    ,leaving_quantity          NUMBER                                             -- ������ʁi�o�ɐ��j
    ,manufacture_date          ic_lots_mst.attribute1%TYPE                        -- �����N����
    ,expiration_date           ic_lots_mst.attribute3%TYPE                        -- �ܖ�����
    ,uniqe_sign                ic_lots_mst.attribute2%TYPE                        -- �ŗL�L��
    ,item_um                   ic_item_mst_b.attribute24%TYPE                     -- �P��
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
    ,month_stock_be            xxinv_stc_inventory_month_stck.monthly_stock%TYPE  -- �O�����݌�
    ,cargo_stock_be            xxinv_stc_inventory_month_stck.cargo_stock%TYPE    -- �O�����ϑ����݌�
    ,month_stock_nw            xxinv_stc_inventory_month_stck.monthly_stock%TYPE  -- �������݌�
    ,cargo_stock_nw            xxinv_stc_inventory_month_stck.cargo_stock%TYPE    -- �������ϑ����݌�
    ,case_amt                  xxinv_stc_inventory_result.case_amt%TYPE           -- �I���P�[�X��
    ,loose_amt                 xxinv_stc_inventory_result.loose_amt%TYPE          -- �I���o��
-- 08/07/16 Y.Yamamoto ADD v1.14 Start
    ,trans_cnt                 NUMBER                                             -- �g�����U�N�V�����n�f�[�^�̒��o����
-- 08/07/16 Y.Yamamoto ADD v1.14 End
-- 08/05/07 Y.Yamamoto ADD v1.1 End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gd_exec_date                 DATE ;                                             -- ���{��
  gd_max_date                  DATE ;                                             -- �ő���`�F�b�N�p
  gd_date_ym_first             DATE ;                                             -- �p�����[�^�̑Ώ۔N���̌�����
  gd_date_ym_last              DATE ;                                             -- �p�����[�^�̑Ώ۔N���̌�����
  gv_date_ym_before            VARCHAR2(6) ;                                      -- �p�����[�^�̑Ώ۔N���̑O��
  gv_department_code           VARCHAR2(10) ;                                     -- �S������
  gv_department_name           VARCHAR2(14) ;                                     -- �S����
  gv_employee_div              per_all_people_f.attribute3%TYPE ;                 -- �]�ƈ��敪
--
  gt_main_data                 tab_data_type_dtl ;                                -- �擾���R�[�h�\
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt          EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt              EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt       EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
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
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XML�f�[�^�i�[
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
    iox_xml_data      IN OUT NOCOPY XML_DATA,
    iv_tag_name       IN     VARCHAR2,
    iv_tag_value      IN     VARCHAR2,
    ic_tag_type       IN     CHAR,
    ic_tag_value_type IN     CHAR)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xml_plsql_table'; -- �v���O������
--
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    i NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    i:= iox_xml_data.COUNT + 1 ;
    iox_xml_data(i).TAG_NAME  := iv_tag_name;
--
    IF (ic_tag_value_type = 'P') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'FM99990.900');
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'FM9999990.90');
    ELSE
      iox_xml_data(i).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data(i).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- �v���O������
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
    ln_cnt                    NUMBER ;        -- ���݃`�F�b�N�p�J�E���^
    ln_ret_num                NUMBER ;        -- ���ʊ֐��߂�l�F���l�^
    lv_err_code               VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �Ώ۔N���`�F�b�N
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.iv_date_ym ) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_err_code := gc_xxinv_10115 ;
      RAISE parameter_check_expt ;
    END IF ;
--
    -- �������`�F�b�N
-- 08/07/16 Y.Yamamoto Update v1.14 Start
--    IF ( ir_param.iv_date_ym > TO_CHAR( SYSDATE, gc_char_ym_format ) ) THEN
    IF ( ir_param.iv_date_ym > TO_CHAR( TRUNC( SYSDATE ), gc_char_ym_format ) ) THEN
-- 08/07/16 Y.Yamamoto Update v1.14 End
      lv_err_code := gc_xxinv_10116 ;
      RAISE parameter_check_expt ;
    END IF ;
--
    -- �Ώ۔N���̌������̐ݒ�
    gd_date_ym_first  := FND_DATE.STRING_TO_DATE( ir_param.iv_date_ym || gc_first_day, gc_char_d_format );
    -- �Ώ۔N���̌������̐ݒ�
    gd_date_ym_last   := LAST_DAY( gd_date_ym_first );
    -- �Ώ۔N���̑O��
    gv_date_ym_before := TO_CHAR( ADD_MONTHS( gd_date_ym_first, -1 ), gc_char_ym_format );
--
    -- ====================================================
    -- �i�ڃR�[�h�`�F�b�N
    -- ====================================================
    -- �i�ڃR�[�h1
    IF ( ir_param.iv_item_no1 IS NOT NULL ) THEN
      -- �i�ڃR�[�h1�Ə��i�敪
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_class
      AND    xicv.category_set_name = gc_cat_item_class_shohin
      AND    xicv.item_no           = ir_param.iv_item_no1
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
--
      -- �i�ڃR�[�h1�ƕi�ڋ敪
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_div
      AND    xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.item_no           = ir_param.iv_item_no1
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �i�ڃR�[�h2
    IF ( ir_param.iv_item_no2 IS NOT NULL ) THEN
      -- �i�ڃR�[�h2�Ə��i�敪
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_class
      AND    xicv.category_set_name = gc_cat_item_class_shohin
      AND    xicv.item_no           = ir_param.iv_item_no2
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
--
      -- �i�ڃR�[�h2�ƕi�ڋ敪
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_div
      AND    xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.item_no           = ir_param.iv_item_no2
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �i�ڃR�[�h3
    IF ( ir_param.iv_item_no3 IS NOT NULL ) THEN
      -- �i�ڃR�[�h3�Ə��i�敪
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_class
      AND    xicv.category_set_name = gc_cat_item_class_shohin
      AND    xicv.item_no           = ir_param.iv_item_no3
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
--
      -- �i�ڃR�[�h3�ƕi�ڋ敪
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_div
      AND    xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.item_no           = ir_param.iv_item_no3
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �q�ɃR�[�h�`�F�b�N
    -- ====================================================
    -- �q�ɃR�[�h1
    IF ( ir_param.iv_whse_code1 IS NOT NULL ) THEN
      SELECT COUNT( xilv.whse_code )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_code     = ir_param.iv_whse_code1
      AND    xilv.disable_date IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM             = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10112 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �q�ɃR�[�h2
    IF ( ir_param.iv_whse_code2 IS NOT NULL ) THEN
      SELECT COUNT( xilv.whse_code )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_code     = ir_param.iv_whse_code2
      AND    xilv.disable_date IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM        = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10112 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �q�ɃR�[�h3
    IF ( ir_param.iv_whse_code3 IS NOT NULL ) THEN
      SELECT COUNT( xilv.whse_code )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_code     = ir_param.iv_whse_code3
      AND    xilv.disable_date IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM        = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10112 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �u���b�N�`�F�b�N
    -- ====================================================
    -- �u���b�N�R�[�h1
    IF ( ir_param.iv_block_code1 IS NOT NULL ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.distribution_block = ir_param.iv_block_code1
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM                  = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10113 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �u���b�N�R�[�h2
    IF ( ir_param.iv_block_code2 IS NOT NULL ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.distribution_block = ir_param.iv_block_code2
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10113 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �u���b�N�R�[�h3
    IF ( ir_param.iv_block_code3 IS NOT NULL ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.distribution_block = ir_param.iv_block_code3
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10113 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �q�ɊǗ������ƃu���b�N�`�F�b�N
    -- ====================================================
    -- �q�ɊǗ�����1�ƃu���b�N�R�[�h1
    IF ( ( ir_param.iv_whse_dept1 IS NOT NULL ) AND ( ir_param.iv_block_code1 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department    = ir_param.iv_whse_dept1
      AND    xilv.distribution_block = ir_param.iv_block_code1
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �q�ɊǗ�����2�ƃu���b�N�R�[�h2
    IF ( ( ir_param.iv_whse_dept2 IS NOT NULL ) AND ( ir_param.iv_block_code2 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department    = ir_param.iv_whse_dept2
      AND    xilv.distribution_block = ir_param.iv_block_code2
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �q�ɊǗ�����3�ƃu���b�N�R�[�h3
    IF ( ( ir_param.iv_whse_dept3 IS NOT NULL ) AND ( ir_param.iv_block_code3 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department    = ir_param.iv_whse_dept3
      AND    xilv.distribution_block = ir_param.iv_block_code3
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �q�ɊǗ������Ƒq�ɃR�[�h�`�F�b�N
    -- ====================================================
    -- �q�ɊǗ�����1�Ƒq�ɃR�[�h1
    IF ( ( ir_param.iv_whse_dept1 IS NOT NULL ) AND ( ir_param.iv_whse_code1 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department = ir_param.iv_whse_dept1
      AND    xilv.whse_code       = ir_param.iv_whse_code1
      AND    xilv.disable_date   IS NULL
      AND    gd_date_ym_first    BETWEEN xilv.date_from
                                     AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM               = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �q�ɊǗ�����2�Ƒq�ɃR�[�h2
    IF ( ( ir_param.iv_whse_dept2 IS NOT NULL ) AND ( ir_param.iv_whse_code2 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department = ir_param.iv_whse_dept2
      AND    xilv.whse_code       = ir_param.iv_whse_code2
      AND    xilv.disable_date   IS NULL
      AND    gd_date_ym_first    BETWEEN xilv.date_from
                                     AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM               = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- �q�ɊǗ�����3�Ƒq�ɃR�[�h3
    IF ( ( ir_param.iv_whse_dept3 IS NOT NULL ) AND ( ir_param.iv_whse_code3 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department = ir_param.iv_whse_dept3
      AND    xilv.whse_code       = ir_param.iv_whse_code3
      AND    xilv.disable_date   IS NULL
      AND    gd_date_ym_first    BETWEEN xilv.date_from
                                     AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM               = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_call_xxinv550004c
   * Description      : �I���X�i�b�v�V���b�g�쐬�v���O�����ďo(A-2)
   ***********************************************************************************/
  PROCEDURE prc_call_xxinv550004c
    (
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_call_xxinv550004c' ; -- �v���O������
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
    ln_ret_num        NUMBER ;        -- �֐��߂�l�F���l�^
    lv_err_code       VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    create_snap_expt  EXCEPTION ;     -- �I���X�i�b�v�V���b�g�쐬�G���[
--
--mod start 1.6
    PRAGMA EXCEPTION_INIT(create_snap_expt,-20001);
--mod end 1.6
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �I���X�i�b�v�V���b�g�쐬�v���O�����ďo
    -- ====================================================
    ln_ret_num := xxinv550004c.create_snapshot( ir_param.iv_date_ym     -- �Ώ۔N��
                                               ,ir_param.iv_whse_code1  -- �q�ɃR�[�h1
                                               ,ir_param.iv_whse_code2  -- �q�ɃR�[�h2
                                               ,ir_param.iv_whse_code3  -- �q�ɃR�[�h3
                                               ,ir_param.iv_whse_dept1  -- �q�ɊǗ�����1
                                               ,ir_param.iv_whse_dept2  -- �q�ɊǗ�����2
                                               ,ir_param.iv_whse_dept3  -- �q�ɊǗ�����3
                                               ,ir_param.iv_block_code1 -- �u���b�N1
                                               ,ir_param.iv_block_code2 -- �u���b�N2
                                               ,ir_param.iv_block_code3 -- �u���b�N3
                                               ,ir_param.iv_item_class  -- ���i�敪
                                               ,ir_param.iv_item_div    -- �i�ڋ敪
                                              )
    ;
    IF ( ln_ret_num <> 0 ) THEN
      lv_err_code := gc_xxinv_10117 ;
      RAISE create_snap_expt ;
    END IF ;
--
  EXCEPTION
    --*** �I���X�i�b�v�V���b�g�쐬�G���[��O ***
    WHEN create_snap_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
--mod start 1.6
--      ov_errbuf  := lv_errmsg ;
      ov_errbuf := sqlerrm;
--mod end 1.6
      ov_retcode := gv_status_error ;
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
  END prc_call_xxinv550004c ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���E�J�[�\���i�i�ڋ敪�i���i�j�j ***
    CURSOR cur_main_data_seihin
      (
           in_whse_dept1   mtl_item_locations.attribute3%TYPE   -- 02 : �q�ɊǗ�����1
          ,in_whse_dept2   mtl_item_locations.attribute3%TYPE   -- 03 : �q�ɊǗ�����2
          ,in_whse_dept3   mtl_item_locations.attribute3%TYPE   -- 04 : �q�ɊǗ�����3
          ,in_whse_code1   ic_whse_mst.whse_code%TYPE           -- 05 : �q�ɃR�[�h1
          ,in_whse_code2   ic_whse_mst.whse_code%TYPE           -- 06 : �q�ɃR�[�h2
          ,in_whse_code3   ic_whse_mst.whse_code%TYPE           -- 07 : �q�ɃR�[�h3
          ,in_block_code1  fnd_lookup_values.lookup_code%TYPE   -- 08 : �u���b�N1
          ,in_block_code2  fnd_lookup_values.lookup_code%TYPE   -- 09 : �u���b�N2
          ,in_block_code3  fnd_lookup_values.lookup_code%TYPE   -- 10 : �u���b�N3
          ,in_item_class   fnd_lookup_values.lookup_code%TYPE   -- 11 : ���i�敪
          ,in_um_class     fnd_lookup_values.lookup_code%TYPE   -- 12 : �P��
          ,in_item_div     fnd_lookup_values.lookup_code%TYPE   -- 13 : �i�ڋ敪
          ,in_item_no1     ic_item_mst_b.item_no%TYPE           -- 14 : �i�ڃR�[�h1
          ,in_item_no2     ic_item_mst_b.item_no%TYPE           -- 15 : �i�ڃR�[�h2
          ,in_item_no3     ic_item_mst_b.item_no%TYPE           -- 16 : �i�ڃR�[�h3
          ,in_create_date1 VARCHAR2                             -- 17 : �����N����1
          ,in_create_date2 VARCHAR2                             -- 18 : �����N����2
          ,in_create_date3 VARCHAR2                             -- 19 : �����N����3
          ,in_lot_no1      ic_lots_mst.lot_no%TYPE              -- 20 : ���b�gNo1
          ,in_lot_no2      ic_lots_mst.lot_no%TYPE              -- 21 : ���b�gNo2
          ,in_lot_no3      ic_lots_mst.lot_no%TYPE              -- 22 : ���b�gNo3
      )
    IS
    SELECT xilv.whse_code                                       -- �q�ɃR�[�h
          ,ximv.item_id                                         -- �i��ID
          ,ximv.item_no                                         -- �i�ڃR�[�h
          ,ilm.lot_no                                           -- ���b�gNo
          ,ilm.lot_id                                           -- ���b�gID
          ,SUM( NVL( xrpm.stock_quantity,   0 ) )
                                           AS stock_quantity    -- ������ʁi���ɐ��j
          ,SUM( NVL( xrpm.leaving_quantity, 0 ) )
                                           AS leaving_quantity  -- ������ʁi�o�ɐ��j
          ,ilm.attribute1  AS manufacture_date                  -- �����N����
          ,ilm.attribute3  AS expiration_date                   -- �ܖ�����
          ,ilm.attribute2  AS uniqe_sign                        -- �ŗL�L��
          ,CASE
            WHEN ( in_um_class = gc_um_class_honsu ) THEN
              ximv.item_um                                      -- �P�ʋ敪�i�{���j�̂Ƃ��͒P�ʂ��擾
            WHEN ( in_um_class = gc_um_class_case  ) THEN
              ximv.conv_unit                                    -- �P�ʋ敪�i�P�[�X�j�̂Ƃ��͓��o�Ɋ��Z�P�ʂ��擾
           END                                       item_um
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
          ,SUM( NVL(xrpm.month_stock_be,0 )) AS month_stock_be  -- �O�����݌ɐ�
          ,SUM( NVL(xrpm.cargo_stock_be,0 )) AS cargo_stock_be  -- �O���ϑ����݌ɐ�
          ,SUM( NVL(xrpm.month_stock_nw,0 )) AS month_stock_nw  -- �������݌ɐ�
          ,SUM( NVL(xrpm.cargo_stock_nw,0 )) AS cargo_stock_nw  -- �����ϑ����݌ɐ�
          ,SUM( NVL(xrpm.case_amt,0  ))      AS case_amt        -- �I���P�[�X��
          ,SUM( NVL(xrpm.loose_amt,0 ))      AS loose_amt       -- �I���o��
          ,SUM( NVL(xrpm.trans_cnt,0 ))      AS trans_cnt       -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/05/07 Y.Yamamoto ADD v1.1 End
    FROM   xxcmn_item_locations2_v                   xilv       -- OPM�ۊǏꏊ���VIEW2
          ,xxcmn_item_mst2_v                         ximv       -- OPM�i�ڏ��VIEW2
-- 08/07/23 Y.Yamamoto ADD v1.14 Start
-- �p�t�H�[�}���X�Ή��̂��߁A�Q�Ƃ���J�e�S���������VIEW���S���T�ɕύX
--          ,xxcmn_item_categories4_v                  xicv       -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_categories5_v                  xicv       -- OPM�i�ڃJ�e�S���������VIEW5
-- 08/07/23 Y.Yamamoto ADD v1.14 End
          ,ic_lots_mst                               ilm        -- OPM���b�g�}�X�^
          ,(SELECT  xrpmv.whse_code                             -- �q�ɃR�[�h
                   ,xrpmv.location                              -- �ۊǑq�ɃR�[�h
                   ,xrpmv.item_id                               -- �i��ID
                   ,xrpmv.lot_id                                -- ���b�gID
                   ,TRUNC( xrpmv.trans_date ) AS trans_date     -- �g�����U�N�V�������t
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_uke ) THEN
                       xrpmv.trans_qty                          -- �󕥋敪�i����j
                    END                       stock_quantity    -- ������ʁi���ɐ��j
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_harai ) THEN
                       xrpmv.trans_qty                          -- �󕥋敪�i���o�j
                    END                       leaving_quantity  -- ������ʁi�o�ɐ��j
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                   ,xrpmv.month_stock_be                        -- �O�����݌ɐ�
                   ,xrpmv.cargo_stock_be                        -- �O���ϑ����݌ɐ�
                   ,xrpmv.month_stock_nw                        -- �������݌ɐ�
                   ,xrpmv.cargo_stock_nw                        -- �����ϑ����݌ɐ�
                   ,xrpmv.case_amt                              -- �I���P�[�X��
                   ,xrpmv.loose_amt                             -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                   ,xrpmv.trans_cnt                             -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                           -- �����^�C�v"ADJI"�i�݌ɒ����j�̒��o
            FROM ( SELECT  itc_adji.whse_code
                          ,itc_adji.location
                          ,itc_adji.item_id
                          ,itc_adji.lot_id
                          ,itc_adji.trans_date
                          ,itc_adji.trans_qty
                          ,xrpm6v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst6_v      xrpm6v     -- �󕥋敪���VIEW_ADJI
                          ,ic_tran_cmp               itc_adji   -- OPM�����݌Ƀg�����U�N�V����
                          ,ic_adjs_jnl               iaj_adji   -- OPM�݌ɒ����W���[�i��
                          ,ic_jrnl_mst               ijm_adji   -- OPM�W���[�i���}�X�^
                          ,(SELECT gc_reason_adji_xrart as reason_code
                                  ,ijm_x201.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x201
                                  ,xxpo_rcv_and_rtn_txns     xrart_adji -- ����ԕi���сi�A�h�I���j
                            WHERE  TO_NUMBER( ijm_x201.attribute1 ) = xrart_adji.txns_id
                            UNION
                            SELECT gc_reason_adji_xnpt  as reason_code
                                  ,ijm_x988.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x988
                                  ,xxpo_namaha_prod_txns     xnpt_adji  -- ���t���сi�A�h�I���j
                            WHERE  ijm_x988.attribute1              = xnpt_adji.entry_number
-- 08/07/22 Y.Yamamoto Delete v1.14 Start
--                            UNION
--                            SELECT gc_reason_adji_xvst  as reason_code
--                                  ,ijm_x977.attribute1  as attribute1
--                            FROM   ic_jrnl_mst               ijm_x977
--                                  ,xxpo_vendor_supply_txns   xvst_adji  -- �O���o�������сi�A�h�I���j
--                            WHERE  TO_NUMBER( ijm_x977.attribute1 ) = xvst_adji.txns_id
--                            AND    xvst_adji.txns_type              = gc_xvst_txns_type_1
-- 08/07/22 Y.Yamamoto Delete v1.14 End
                            UNION
                            SELECT gc_reason_adji_xmril as reason_code
                                  ,ijm_x123.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x123
                                  ,xxinv_mov_req_instr_lines xmril_adji -- �ړ��˗�/�w�����ׁi�A�h�I���j
                            WHERE  TO_NUMBER( ijm_x123.attribute1 ) = xmril_adji.mov_line_id 
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                            UNION -- �d���h�~�̂��߂̃_�~�[�f�[�^
                            SELECT gc_doc_type_adji     as reason_code
                                  ,NULL                 as attribute1
                            FROM   DUAL
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                           ) xx_data                                    -- �e�A�h�I���ɑ��݂���f�[�^
                    WHERE  itc_adji.doc_type                 = gc_doc_type_adji
                    AND    xrpm6v.use_div_invent             = gc_use_div_invent_y
                    AND    iaj_adji.journal_id               = ijm_adji.journal_id
-- 08/07/22 Y.Yamamoto Update v1.14 Start
--                    AND    itc_adji.reason_code              = xx_data.reason_code
--                    AND    ijm_adji.attribute1               = xx_data.attribute1
                    AND (((ijm_adji.attribute1               IS NULL)
                      AND (xx_data.reason_code               = gc_doc_type_adji))
                     OR  ((ijm_adji.attribute1               IS NOT NULL)
                      AND ((itc_adji.reason_code             = xx_data.reason_code)
                      AND  (ijm_adji.attribute1              = xx_data.attribute1))
                      OR  ((itc_adji.reason_code             = gc_reason_adji_xvst)
                      AND  (xx_data.reason_code              = gc_doc_type_adji))))
-- 08/07/22 Y.Yamamoto Update v1.14 End
                    AND    itc_adji.doc_type                 = iaj_adji.trans_type
                    AND    itc_adji.doc_id                   = iaj_adji.doc_id
                    AND    itc_adji.doc_line                 = iaj_adji.doc_line
                    AND    xrpm6v.doc_type                   = itc_adji.doc_type
                    AND    xrpm6v.reason_code                = itc_adji.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm6v.rcv_pay_div                = SIGN( itc_adji.trans_qty )
                    AND    xrpm6v.rcv_pay_div                = TO_CHAR( SIGN( itc_adji.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"TRNI"�i�ϑ��Ȃ��ړ��j�̒��o
                    UNION ALL  -- �����^�C�v"TRNI"�i�ϑ��Ȃ��ړ��j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itc_trni.whse_code
                          ,itc_trni.location
                          ,itc_trni.item_id
                          ,itc_trni.lot_id
                          ,itc_trni.trans_date
                          ,itc_trni.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- �󕥋敪���VIEW_�q�Ɋ֘A
                          ,ic_tran_cmp               itc_trni   -- OPM�����݌Ƀg�����U�N�V����
                          ,ic_adjs_jnl               iaj_trni   -- OPM�݌ɒ����W���[�i��
                          ,ic_jrnl_mst               ijm_trni   -- OPM�W���[�i���}�X�^
                          ,xxinv_mov_req_instr_lines xmril_trni -- �ړ��˗�/�w�����ׁi�A�h�I���j
                          ,( SELECT itc_b.whse_code
                                   ,itc_b.doc_id
                                   ,COUNT(*)      AS itc_cnt
                             FROM   ic_tran_cmp      itc_b      -- OPM�����݌Ƀg�����U�N�V����
                             WHERE  itc_b.doc_type          = gc_doc_type_trni
                             GROUP BY itc_b.whse_code
                                     ,itc_b.doc_id
                           )                         itc_trni_cnt
                    WHERE  itc_trni.doc_type                = gc_doc_type_trni
                    AND    xrpm9v.doc_type                  = gc_doc_type_trni
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    iaj_trni.journal_id              = ijm_trni.journal_id
                    AND    TO_NUMBER( ijm_trni.attribute1 ) = xmril_trni.mov_line_id
                    AND    itc_trni.doc_type                = iaj_trni.trans_type
                    AND    itc_trni.doc_id                  = iaj_trni.doc_id
                    AND    itc_trni.doc_line                = iaj_trni.doc_line
                    AND    xrpm9v.doc_type                  = itc_trni.doc_type
                    AND    xrpm9v.reason_code               = itc_trni.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itc_trni.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itc_trni.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itc_trni_cnt.whse_code           = itc_trni.whse_code
                    AND    itc_trni_cnt.doc_id              = itc_trni.doc_id
                    AND    itc_trni_cnt.itc_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"XFER"�i�ϑ�����ړ��j�̒��o
                    UNION ALL  -- �����^�C�v"XFER"�i�ϑ�����ړ��j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_xfer.whse_code
                          ,itp_xfer.location
                          ,itp_xfer.item_id
                          ,itp_xfer.lot_id
                          ,itp_xfer.trans_date
                          ,itp_xfer.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- �󕥋敪���VIEW_�q�Ɋ֘A
                          ,ic_tran_pnd               itp_xfer   -- OPM�ۗ��݌Ƀg�����U�N�V����
                          ,ic_xfer_mst               ixm_xfer   -- OPM�݌ɓ]���}�X�^
                          ,xxinv_mov_req_instr_lines xmril_xfer -- �ړ��˗�/�w�����ׁi�A�h�I���j
                          ,( SELECT itp_b.whse_code
                                   ,itp_b.doc_id
                                   ,COUNT(*)      AS itp_cnt
                             FROM   ic_tran_pnd      itp_b      -- OPM�ۗ��݌Ƀg�����U�N�V����
                             WHERE  itp_b.doc_type          = gc_doc_type_xfer
                             AND    itp_b.completed_ind     = gc_completed_ind_1
                             GROUP BY itp_b.whse_code
                                     ,itp_b.doc_id
                           )                         itp_xfer_cnt
                    WHERE  itp_xfer.doc_type                = gc_doc_type_xfer
                    AND    itp_xfer.completed_ind           = gc_completed_ind_1
                    AND    xrpm9v.doc_type                  = gc_doc_type_xfer
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    TO_NUMBER( ixm_xfer.attribute1 ) = xmril_xfer.mov_line_id
                    AND    itp_xfer.doc_id                  = ixm_xfer.transfer_id
                    AND    xrpm9v.doc_type                  = itp_xfer.doc_type
                    AND    xrpm9v.reason_code               = itp_xfer.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itp_xfer.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itp_xfer.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itp_xfer_cnt.whse_code           = itp_xfer.whse_code
                    AND    itp_xfer_cnt.doc_id              = itp_xfer.doc_id
                    AND    itp_xfer_cnt.itp_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"OMSO"�i�󒍁j�̒��o
                    UNION ALL  -- �����^�C�v"OMSO"�i�󒍁j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_omso.whse_code
                          ,itp_omso.location
                          ,itp_omso.item_id
                          ,itp_omso.lot_id
                          ,itp_omso.trans_date
                          ,itp_omso.trans_qty
                          ,xrpm7v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst7_v      xrpm7v     -- �󕥋敪���VIEW_OMSO
                          ,ic_tran_pnd               itp_omso   -- OPM�ۗ��݌Ƀg�����U�N�V����
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                          ,ic_lots_mst               ilm_omso   -- OPM���b�g�}�X�^
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                    WHERE  itp_omso.doc_type                = gc_doc_type_omso
                    AND    itp_omso.completed_ind           = gc_completed_ind_1
                    AND    xrpm7v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm7v.doc_type                  = itp_omso.doc_type
                    AND    xrpm7v.line_id                   = itp_omso.line_id
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                    AND    xrpm7v.lot_number                = ilm_omso.lot_no
                    AND    itp_omso.item_id                 = ilm_omso.item_id
                    AND    itp_omso.lot_id                  = ilm_omso.lot_id
-- 08/07/08 Y.Yamamoto ADD v1.14 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"PROD"�i���Y�j�̒��o
                    UNION ALL  -- �����^�C�v"PROD"�i���Y�j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_prod.whse_code
                          ,itp_prod.location
                          ,itp_prod.item_id
                          ,itp_prod.lot_id
                          ,itp_prod.trans_date
                          ,itp_prod.trans_qty
                          ,xrpm2v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst2_v      xrpm2v     -- �󕥋敪���VIEW���Y
                          ,ic_tran_pnd               itp_prod   -- OPM�ۗ��݌Ƀg�����U�N�V����
                    WHERE  itp_prod.doc_type                = gc_doc_type_prod
                    AND    itp_prod.completed_ind           = gc_completed_ind_1
                    AND    xrpm2v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm2v.doc_type                  = itp_prod.doc_type
                    AND    xrpm2v.doc_id                    = itp_prod.doc_id
                    AND    xrpm2v.doc_line                  = itp_prod.doc_line
                    AND    xrpm2v.line_type                 = itp_prod.line_type
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"PORC"�i�����j�̒��o
                    UNION ALL  -- �����^�C�v"PORC"�i�����j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_porc.whse_code
                          ,itp_porc.location
                          ,itp_porc.item_id
                          ,itp_porc.lot_id
                          ,itp_porc.trans_date
                          ,itp_porc.trans_qty
                          ,xrpm8v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst8_v      xrpm8v     -- �󕥋敪���VIEW_PORC
                          ,ic_tran_pnd               itp_porc   -- OPM�ۗ��݌Ƀg�����U�N�V����
                    WHERE  itp_porc.doc_type                = gc_doc_type_porc
                    AND    itp_porc.completed_ind           = gc_completed_ind_1
                    AND    xrpm8v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm8v.doc_type                  = itp_porc.doc_type
                    AND    xrpm8v.doc_id                    = itp_porc.doc_id
                    AND    xrpm8v.doc_line                  = itp_porc.doc_line
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �O�����݌ɂ̒��o
                    UNION ALL  -- �O�����݌ɂ̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_be.whse_code
                          ,xilv_be.segment1                        AS location
                          ,xsims_be.item_id
                          ,xsims_be.lot_id
                          ,gd_date_ym_first      AS trans_date       -- �O���̃f�[�^�Ȃ̂Ō������邽��
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,SUM( NVL( xsims_be.monthly_stock, 0 ) ) AS month_stock_be  -- �����݌ɐ�
                          ,SUM( NVL( xsims_be.cargo_stock,   0 ) ) AS cargo_stock_be  -- �ϑ����݌ɐ�
                          ,0                     AS month_stock_nw   -- �������݌ɐ�
                          ,0                     AS cargo_stock_nw   -- �����ϑ����݌ɐ�
                          ,0                     AS case_amt         -- �I���P�[�X��
                          ,0                     AS loose_amt        -- �I���o��
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_be   -- �I�������݌Ƀe�[�u��
                          ,xxcmn_item_locations_v xilv_be
                    WHERE  xsims_be.invent_ym = gv_date_ym_before    -- �I���N���O���̂���
                    AND    xilv_be.whse_code = xsims_be.whse_code
                    AND    xilv_be.segment1 = ( SELECT MIN( x.segment1 )
                                                FROM   xxcmn_item_locations_v x
                                                WHERE  x.whse_code = xsims_be.whse_code )
                    GROUP BY xsims_be.whse_code                      -- �q�ɃR�[�h
                            ,xilv_be.segment1
                            ,xsims_be.item_id                        -- �i��ID
                            ,xsims_be.lot_id                         -- ���b�gID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����݌ɂ̒��o
                    UNION ALL  -- �����݌ɂ̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_nw.whse_code
                          ,xilv_nw.segment1                        AS location
                          ,xsims_nw.item_id
                          ,xsims_nw.lot_id
                          ,gd_date_ym_first      AS trans_date       -- �������邽��
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- �����݌ɐ�
                          ,0                     AS cargo_stock_be   -- �ϑ����݌ɐ�
                          ,SUM( NVL( xsims_nw.monthly_stock, 0 ) ) AS month_stock_nw  -- �������݌ɐ�
                          ,SUM( NVL( xsims_nw.cargo_stock,   0 ) ) AS cargo_stock_nw  -- �����ϑ����݌ɐ�
                          ,0                     AS case_amt         -- �I���P�[�X��
                          ,0                     AS loose_amt        -- �I���o��
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_nw   -- �I�������݌Ƀe�[�u��
                          ,xxcmn_item_locations_v xilv_nw
                    WHERE  xsims_nw.invent_ym = TO_CHAR( gd_date_ym_first, gc_char_ym_format ) -- �I���N�������̂���
                    AND    xilv_nw.whse_code = xsims_nw.whse_code
                    AND    xilv_nw.segment1 = ( SELECT MIN( y.segment1 )
                                                FROM   xxcmn_item_locations_v y
                                                WHERE  y.whse_code = xsims_nw.whse_code )
                    GROUP BY xsims_nw.whse_code                      -- �q�ɃR�[�h
                            ,xilv_nw.segment1
                            ,xsims_nw.item_id                        -- �i��ID
                            ,xsims_nw.lot_id                         -- ���b�gID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �I�����ʏ��̒��o
                    UNION ALL  -- �I�����ʏ��̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsir.invent_whse_code AS whse_code
                          ,xilv_sir.segment1                       AS location
                          ,xsir.item_id
-- 08/05/09 Y.Yamamoto Update v1.3 Start
--                          ,xsir.lot_id
                          ,NVL( xsir.lot_id, 0 ) AS lot_id
-- 08/05/09 Y.Yamamoto Update v1.3 End
                          ,gd_date_ym_first      AS trans_date       -- �������邽��
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- �����݌ɐ�
                          ,0                     AS cargo_stock_be   -- �ϑ����݌ɐ�
                          ,0                     AS month_stock_nw   -- �������݌ɐ�
                          ,0                     AS cargo_stock_nw   -- �����ϑ����݌ɐ�
                          ,SUM( xsir.case_amt )  AS case_amt         -- �I���P�[�X��
                          ,SUM( xsir.loose_amt ) AS loose_amt        -- �I���o��
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_result xsir                     -- �I�����ʃe�[�u��
                          ,xxcmn_item_locations_v xilv_sir
                    WHERE  xsir.invent_date      BETWEEN gd_date_ym_first      -- �p�����[�^�̑Ώ۔N���̂P������
                                                 AND     gd_date_ym_last       -- �������Ŏ擾
                    AND    xilv_sir.whse_code = xsir.invent_whse_code
                    AND    xilv_sir.segment1 = ( SELECT MIN( z.segment1 )
                                                 FROM   xxcmn_item_locations_v z
                                                 WHERE  z.whse_code = xsir.invent_whse_code )
                    GROUP BY xsir.invent_whse_code                             -- �I���q��
                            ,xilv_sir.segment1
                            ,xsir.item_id                                      -- �i��ID
                            ,xsir.lot_id                                       -- ���b�gID
-- 08/05/07 Y.Yamamoto ADD v1.1 End
                  ) xrpmv
           )                                         xrpm       -- �݌Ƀg�������
-- 08/05/20 mod v1.5 start
--          ,( SELECT DISTINCT    ccd.item_id
--             FROM   cm_cmpt_dtl ccd
           ,(SELECT distinct item_id,cost_manage_code
             FROM (
               --�W��
               SELECT ccd.item_id,gc_cost_manage_code_hyozyun cost_manage_code
               FROM   cm_cmpt_dtl ccd
                     ,xxcmn_item_mst2_v ximv
               WHERE nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) = gc_cost_manage_code_hyozyun
               AND ccd.item_id = ximv.item_id
               --�W���ȊO
               union all
               SELECT ximv.item_id,gc_cost_manage_code_jissei cost_manage_code
               FROM   xxcmn_item_mst2_v ximv
               WHERE  nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) != gc_cost_manage_code_hyozyun
             )
-- 08/05/20 mod v1.5 end
           )                                         ccd_item        -- �i�ڌ����}�X�^
    WHERE  ccd_item.item_id             = ximv.item_id
-- 08/05/20 add v1.5 start
    AND    DECODE(ximv.cost_manage_code
                   ,gc_cost_manage_code_hyozyun,gc_cost_manage_code_hyozyun
                                               ,gc_cost_manage_code_jissei) = ccd_item.cost_manage_code
-- 08/05/20 add v1.5 end
    AND    xicv.item_id                 = ximv.item_id
    AND    ilm.item_id                  = ximv.item_id
    AND    gd_date_ym_first       BETWEEN ximv.start_date_active
                                      AND ximv.end_date_active
    AND    xicv.prod_class_code         = in_item_class
    AND    xicv.item_class_code         = in_item_div
    AND    gd_date_ym_first       BETWEEN xilv.date_from
                                      AND NVL( xilv.date_to, gd_max_date )
    -- ��������݌Ƀg�����Ƃ̌���
    AND    xrpm.whse_code               = xilv.whse_code
    AND  ( xrpm.location                = xilv.segment1
-- 08/05/08 Y.Yamamoto Update v1.1 Start
--        OR xrpm.lot_id                  = 0 )
        OR (ximv.lot_ctl                = 0
          AND xilv.segment1 = ( SELECT MIN( zz.segment1 )
                                FROM   xxcmn_item_locations_v zz
                                WHERE  zz.whse_code = xilv.whse_code ) ) )
-- 08/05/08 Y.Yamamoto Update v1.1 End
    AND    xrpm.item_id                 = ximv.item_id
    AND    xrpm.lot_id                  = ilm.lot_id
    AND    xrpm.trans_date        BETWEEN gd_date_ym_first
                                      AND gd_date_ym_last
    -- ��������p�����[�^�����Ƃ̌���
--mod start 2.2
/*
    AND (((( xilv.whse_code             = in_whse_code1  )
      OR  (  xilv.whse_code             = in_whse_code2  )
      OR  (  xilv.whse_code             = in_whse_code3  ) )
     OR  ((  xilv.distribution_block    = in_block_code1 )
      OR  (  xilv.distribution_block    = in_block_code2 )
      OR  (  xilv.distribution_block    = in_block_code3 ) ) )
     OR   (  in_whse_code1  IS NULL AND in_whse_code2  IS NULL AND in_whse_code3  IS NULL
         AND in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL ) )
-- 08/05/09 Y.Yamamoto Update v1.2 Start
--    AND  ((( in_whse_dept1             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept1 ) )
--     AND ( ( in_whse_dept2             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept2 ) )
--     AND ( ( in_whse_dept3             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
--    AND  ((( in_item_no1               IS NULL )
--        OR ( ximv.item_no               = in_item_no1 ) )
--     AND ( ( in_item_no2               IS NULL )
--        OR ( ximv.item_no               = in_item_no2 ) )
--     AND ( ( in_item_no3               IS NULL )
--        OR ( ximv.item_no               = in_item_no3 ) ) )
--    AND  ((( in_lot_no1                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no1 ) )
--     AND ( ( in_lot_no2                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no2 ) )
--     AND ( ( in_lot_no3                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
--    AND  ((( in_create_date1           IS NULL )
--        OR ( ilm.attribute1             = in_create_date1 ) )
--     AND ( ( in_create_date2           IS NULL )
--        OR ( ilm.attribute1             = in_create_date2 ) )
--     AND ( ( in_create_date3           IS NULL )
--        OR ( ilm.attribute1             = in_create_date3 ) ) )
    AND  ((( in_whse_dept1             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept1 ) )
     OR  ( ( in_whse_dept2             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept2 ) )
     OR  ( ( in_whse_dept3             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
    AND  ((( in_item_no1               IS NULL )
        OR ( ximv.item_no               = in_item_no1 ) )
     OR  ( ( in_item_no2               IS NULL )
        OR ( ximv.item_no               = in_item_no2 ) )
     OR  ( ( in_item_no3               IS NULL )
        OR ( ximv.item_no               = in_item_no3 ) ) )
    AND  ((( in_lot_no1                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no1 ) )
     OR  ( ( in_lot_no2                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no2 ) )
     OR  ( ( in_lot_no3                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
    AND  ((( in_create_date1           IS NULL )
        OR ( ilm.attribute1             = in_create_date1 ) )
     OR  ( ( in_create_date2           IS NULL )
        OR ( ilm.attribute1             = in_create_date2 ) )
     OR  ( ( in_create_date3           IS NULL )
        OR ( ilm.attribute1             = in_create_date3 ) ) )
-- 08/05/09 Y.Yamamoto Update v1.2 End
*/
    --�q�ɊǗ������ɂ��i����
    AND (in_whse_dept1 IS NULL AND in_whse_dept2 IS NULL AND in_whse_dept3 IS NULL
      OR xilv.whse_department IN (in_whse_dept1,in_whse_dept2,in_whse_dept3)
    )
    --�q�ɃR�[�h�ɂ��i����
    AND (in_whse_code1 IS NULL AND in_whse_code2 IS NULL AND in_whse_code3 IS NULL
      OR xilv.whse_code IN (in_whse_code1,in_whse_code2,in_whse_code3)
    )
    --�����u���b�N�ɂ��i����
    AND (in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL
      OR xilv.distribution_block IN (in_block_code1,in_block_code2,in_block_code3)
    )
    --�i�ڃR�[�h�ɂ��i����
    AND (in_item_no1 IS NULL AND in_item_no2 IS NULL AND in_item_no3 IS NULL
      OR ximv.item_no IN (in_item_no1,in_item_no2,in_item_no3)
    )
    --�����N�����ɂ��i����
    AND (in_create_date1 IS NULL AND in_create_date2 IS NULL AND in_create_date3 IS NULL
      OR ilm.attribute1 IN (in_create_date1,in_create_date2,in_create_date3)
    )
    --���b�gNo�ɂ��i����
    AND (in_lot_no1 IS NULL AND in_lot_no2 IS NULL AND in_lot_no3 IS NULL
      OR ilm.lot_no IN (in_lot_no1,in_lot_no2,in_lot_no3)
    )
--mod end 2.2
    GROUP BY  xilv.whse_code                                                 -- �q�ɃR�[�h
             ,ximv.item_id                                                   -- �i��ID
             ,ximv.item_no                                                   -- �i�ڃR�[�h
             ,ilm.lot_no                                                     -- ���b�gNo
             ,ilm.lot_id                                                     -- ���b�gID
             ,ilm.attribute1                                                 -- �����N����
             ,ilm.attribute3                                                 -- �ܖ�����
             ,ilm.attribute2                                                 -- �ŗL�L��
             ,ximv.item_um                                                   -- �P��
             ,ximv.conv_unit                                                 -- ���o�Ɋ��Z�P��
-- 08/05/21 v1.7 start
    HAVING NOT (     SUM( NVL(xrpm.month_stock_be,0 )) = 0                   -- �O�����݌ɐ�
                 AND SUM( NVL(xrpm.cargo_stock_be,0 )) = 0                   -- �O���ϑ����݌ɐ�
                 AND SUM( NVL(xrpm.month_stock_nw,0 )) = 0                   -- �������݌ɐ�
                 AND SUM( NVL(xrpm.cargo_stock_nw,0 )) = 0                   -- �����ϑ����݌ɐ�
                 AND SUM( NVL(xrpm.case_amt,0  )) = 0                        -- �I���P�[�X��
                 AND SUM( NVL(xrpm.loose_amt,0 )) = 0                        -- �I���o��
-- 08/07/08 Y.Yamamoto Update v1.14 Start
--                 AND SUM( NVL(xrpm.stock_quantity,0)) = 0                    -- ������ʁi���ɐ��j
--                 AND SUM( NVL(xrpm.leaving_quantity,0)) = 0                  -- ������ʁi�o�ɐ��j
--               )
               )
               OR SUM( NVL(xrpm.trans_cnt,0)) > 0                            -- �g�����n�̃f�[�^������Ƃ���0����
-- 08/07/08 Y.Yamamoto Update v1.14 End
-- 08/05/21 v1.7 end
    ORDER BY xilv.whse_code                                                  -- �q�ɃR�[�h
             ,ximv.item_no                                                   -- �i�ڃR�[�h
             ,ilm.attribute1                                                 -- �����N����
             ,ilm.attribute2                                                 -- �ŗL�L��
    ;
--
    -- *** ���[�J���E�J�[�\���i�i�ڋ敪�i���i�ȊO�j�j ***
    CURSOR cur_main_data_etc
      (
           in_whse_dept1   mtl_item_locations.attribute3%TYPE  -- 02 : �q�ɊǗ�����1
          ,in_whse_dept2   mtl_item_locations.attribute3%TYPE  -- 03 : �q�ɊǗ�����2
          ,in_whse_dept3   mtl_item_locations.attribute3%TYPE  -- 04 : �q�ɊǗ�����3
          ,in_whse_code1   ic_whse_mst.whse_code%TYPE          -- 05 : �q�ɃR�[�h1
          ,in_whse_code2   ic_whse_mst.whse_code%TYPE          -- 06 : �q�ɃR�[�h2
          ,in_whse_code3   ic_whse_mst.whse_code%TYPE          -- 07 : �q�ɃR�[�h3
          ,in_block_code1  fnd_lookup_values.lookup_code%TYPE  -- 08 : �u���b�N1
          ,in_block_code2  fnd_lookup_values.lookup_code%TYPE  -- 09 : �u���b�N2
          ,in_block_code3  fnd_lookup_values.lookup_code%TYPE  -- 10 : �u���b�N3
          ,in_item_class   fnd_lookup_values.lookup_code%TYPE  -- 11 : ���i�敪
          ,in_um_class     fnd_lookup_values.lookup_code%TYPE  -- 12 : �P��
          ,in_item_div     fnd_lookup_values.lookup_code%TYPE  -- 13 : �i�ڋ敪
          ,in_item_no1     ic_item_mst_b.item_no%TYPE          -- 14 : �i�ڃR�[�h1
          ,in_item_no2     ic_item_mst_b.item_no%TYPE          -- 15 : �i�ڃR�[�h2
          ,in_item_no3     ic_item_mst_b.item_no%TYPE          -- 16 : �i�ڃR�[�h3
          ,in_create_date1 VARCHAR2                            -- 17 : �����N����1
          ,in_create_date2 VARCHAR2                            -- 18 : �����N����2
          ,in_create_date3 VARCHAR2                            -- 19 : �����N����3
          ,in_lot_no1      ic_lots_mst.lot_no%TYPE             -- 20 : ���b�gNo1
          ,in_lot_no2      ic_lots_mst.lot_no%TYPE             -- 21 : ���b�gNo2
          ,in_lot_no3      ic_lots_mst.lot_no%TYPE             -- 22 : ���b�gNo3
      )
    IS
    SELECT xilv.whse_code                                       -- �q�ɃR�[�h
          ,ximv.item_id                                         -- �i��ID
          ,ximv.item_no                                         -- �i�ڃR�[�h
          ,ilm.lot_no                                           -- ���b�gNo
          ,ilm.lot_id                                           -- ���b�gID
          ,SUM( NVL( xrpm.stock_quantity,   0 ) )
                                           AS stock_quantity    -- ������ʁi���ɐ��j
          ,SUM( NVL( xrpm.leaving_quantity, 0 ) )
                                           AS leaving_quantity  -- ������ʁi�o�ɐ��j
          ,ilm.attribute1  AS manufacture_date                  -- �����N����
          ,ilm.attribute3  AS expiration_date                   -- �ܖ�����
          ,ilm.attribute2  AS uniqe_sign                        -- �ŗL�L��
          ,CASE
            WHEN ( in_um_class = gc_um_class_honsu ) THEN
              ximv.item_um                                      -- �P�ʋ敪�i�{���j�̂Ƃ��͒P�ʂ��擾
            WHEN ( in_um_class = gc_um_class_case  ) THEN
              ximv.conv_unit                                    -- �P�ʋ敪�i�P�[�X�j�̂Ƃ��͓��o�Ɋ��Z�P�ʂ��擾
           END                                       item_um
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
          ,SUM( NVL(xrpm.month_stock_be,0 )) AS month_stock_be  -- �O�����݌ɐ�
          ,SUM( NVL(xrpm.cargo_stock_be,0 )) AS cargo_stock_be  -- �O���ϑ����݌ɐ�
          ,SUM( NVL(xrpm.month_stock_nw,0 )) AS month_stock_nw  -- �������݌ɐ�
          ,SUM( NVL(xrpm.cargo_stock_nw,0 )) AS cargo_stock_nw  -- �����ϑ����݌ɐ�
          ,SUM( NVL(xrpm.case_amt,0  ))      AS case_amt        -- �I���P�[�X��
          ,SUM( NVL(xrpm.loose_amt,0 ))      AS loose_amt       -- �I���o��
          ,SUM( NVL(xrpm.trans_cnt,0 ))      AS trans_cnt       -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/05/07 Y.Yamamoto ADD v1.1 End
    FROM   xxcmn_item_locations2_v                   xilv       -- OPM�ۊǏꏊ���VIEW2
          ,xxcmn_item_mst2_v                         ximv       -- OPM�i�ڏ��VIEW2
-- 08/07/23 Y.Yamamoto ADD v1.14 Start
-- �p�t�H�[�}���X�Ή��̂��߁A�Q�Ƃ���J�e�S���������VIEW���S���T�ɕύX
--          ,xxcmn_item_categories4_v                  xicv       -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_categories5_v                  xicv       -- OPM�i�ڃJ�e�S���������VIEW5
-- 08/07/23 Y.Yamamoto ADD v1.14 Start
          ,ic_lots_mst                               ilm        -- OPM���b�g�}�X�^
          ,(SELECT  xrpmv.whse_code                             -- �q�ɃR�[�h
                   ,xrpmv.location                              -- �ۊǑq�ɃR�[�h
                   ,xrpmv.item_id                               -- �i��ID
                   ,xrpmv.lot_id                                -- ���b�gID
                   ,TRUNC( xrpmv.trans_date ) AS trans_date     -- �g�����U�N�V�������t
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_uke ) THEN
                       xrpmv.trans_qty                          -- �󕥋敪�i����j
                    END                       stock_quantity    -- ������ʁi���ɐ��j
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_harai ) THEN
                       xrpmv.trans_qty                          -- �󕥋敪�i���o�j
                    END                       leaving_quantity  -- ������ʁi�o�ɐ��j
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                   ,xrpmv.month_stock_be                        -- �O�����݌ɐ�
                   ,xrpmv.cargo_stock_be                        -- �O���ϑ����݌ɐ�
                   ,xrpmv.month_stock_nw                        -- �������݌ɐ�
                   ,xrpmv.cargo_stock_nw                        -- �����ϑ����݌ɐ�
                   ,xrpmv.case_amt                              -- �I���P�[�X��
                   ,xrpmv.loose_amt                             -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                   ,xrpmv.trans_cnt                             -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                           -- �����^�C�v"ADJI"�i�݌ɒ����j�̒��o
            FROM ( SELECT  itc_adji.whse_code
                          ,itc_adji.location
                          ,itc_adji.item_id
                          ,itc_adji.lot_id
                          ,itc_adji.trans_date
                          ,itc_adji.trans_qty
                          ,xrpm6v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst6_v      xrpm6v     -- �󕥋敪���VIEW_ADJI
                          ,ic_tran_cmp               itc_adji   -- OPM�����݌Ƀg�����U�N�V����
                          ,ic_adjs_jnl               iaj_adji   -- OPM�݌ɒ����W���[�i��
                          ,ic_jrnl_mst               ijm_adji   -- OPM�W���[�i���}�X�^
                          ,(SELECT gc_reason_adji_xrart as reason_code
                                  ,ijm_x201.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x201
                                  ,xxpo_rcv_and_rtn_txns     xrart_adji -- ����ԕi���сi�A�h�I���j
                            WHERE  TO_NUMBER( ijm_x201.attribute1 ) = xrart_adji.txns_id
                            UNION
                            SELECT gc_reason_adji_xnpt  as reason_code
                                  ,ijm_x988.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x988
                                  ,xxpo_namaha_prod_txns     xnpt_adji  -- ���t���сi�A�h�I���j
                            WHERE  ijm_x988.attribute1              = xnpt_adji.entry_number
-- 08/07/22 Y.Yamamoto ADD v1.14 Start
--                            UNION
--                            SELECT gc_reason_adji_xvst  as reason_code
--                                  ,ijm_x977.attribute1  as attribute1
--                            FROM   ic_jrnl_mst               ijm_x977
--                                  ,xxpo_vendor_supply_txns   xvst_adji  -- �O���o�������сi�A�h�I���j
--                            WHERE  TO_NUMBER( ijm_x977.attribute1 ) = xvst_adji.txns_id
--                            AND    xvst_adji.txns_type              = gc_xvst_txns_type_1
-- 08/07/22 Y.Yamamoto ADD v1.14 End
                            UNION
                            SELECT gc_reason_adji_xmril as reason_code
                                  ,ijm_x123.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x123
                                  ,xxinv_mov_req_instr_lines xmril_adji -- �ړ��˗�/�w�����ׁi�A�h�I���j
                            WHERE  TO_NUMBER( ijm_x123.attribute1 ) = xmril_adji.mov_line_id 
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                            UNION -- �d���h�~�̂��߂̃_�~�[�f�[�^
                            SELECT gc_doc_type_adji     as reason_code
                                  ,NULL                 as attribute1
                            FROM   DUAL
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                           ) xx_data                                    -- �e�A�h�I���ɑ��݂���f�[�^
                    WHERE  itc_adji.doc_type                 = gc_doc_type_adji
                    AND    xrpm6v.use_div_invent             = gc_use_div_invent_y
                    AND    iaj_adji.journal_id               = ijm_adji.journal_id
-- 08/07/22 Y.Yamamoto Update v1.14 Start
--                    AND    itc_adji.reason_code              = xx_data.reason_code
--                    AND    ijm_adji.attribute1               = xx_data.attribute1
                    AND (((ijm_adji.attribute1               IS NULL)
                      AND (xx_data.reason_code               = gc_doc_type_adji))
                     OR  ((ijm_adji.attribute1               IS NOT NULL)
                      AND ((itc_adji.reason_code             = xx_data.reason_code)
                      AND  (ijm_adji.attribute1              = xx_data.attribute1))
                      OR  ((itc_adji.reason_code             = gc_reason_adji_xvst)
                      AND  (xx_data.reason_code              = gc_doc_type_adji))))
-- 08/07/22 Y.Yamamoto Update v1.14 End
                    AND    itc_adji.doc_type                 = iaj_adji.trans_type
                    AND    itc_adji.doc_id                   = iaj_adji.doc_id
                    AND    itc_adji.doc_line                 = iaj_adji.doc_line
                    AND    xrpm6v.doc_type                   = itc_adji.doc_type
                    AND    xrpm6v.reason_code                = itc_adji.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm6v.rcv_pay_div                = SIGN( itc_adji.trans_qty )
                    AND    xrpm6v.rcv_pay_div                = TO_CHAR( SIGN( itc_adji.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"TRNI"�i�ϑ��Ȃ��ړ��j�̒��o
                    UNION ALL  -- �����^�C�v"TRNI"�i�ϑ��Ȃ��ړ��j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itc_trni.whse_code
                          ,itc_trni.location
                          ,itc_trni.item_id
                          ,itc_trni.lot_id
                          ,itc_trni.trans_date
                          ,itc_trni.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- �󕥋敪���VIEW_�q�Ɋ֘A
                          ,ic_tran_cmp               itc_trni   -- OPM�����݌Ƀg�����U�N�V����
                          ,ic_adjs_jnl               iaj_trni   -- OPM�݌ɒ����W���[�i��
                          ,ic_jrnl_mst               ijm_trni   -- OPM�W���[�i���}�X�^
                          ,xxinv_mov_req_instr_lines xmril_trni -- �ړ��˗�/�w�����ׁi�A�h�I���j
                          ,( SELECT itc_b.whse_code
                                   ,itc_b.doc_id
                                   ,COUNT(*)      AS itc_cnt
                             FROM   ic_tran_cmp      itc_b      -- OPM�����݌Ƀg�����U�N�V����
                             WHERE  itc_b.doc_type          = gc_doc_type_trni
                             GROUP BY itc_b.whse_code
                                     ,itc_b.doc_id
                           )                         itc_trni_cnt
                    WHERE  itc_trni.doc_type                = gc_doc_type_trni
                    AND    xrpm9v.doc_type                  = gc_doc_type_trni
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    iaj_trni.journal_id              = ijm_trni.journal_id
                    AND    TO_NUMBER( ijm_trni.attribute1 ) = xmril_trni.mov_line_id
                    AND    itc_trni.doc_type                = iaj_trni.trans_type
                    AND    itc_trni.doc_id                  = iaj_trni.doc_id
                    AND    itc_trni.doc_line                = iaj_trni.doc_line
                    AND    xrpm9v.doc_type                  = itc_trni.doc_type
                    AND    xrpm9v.reason_code               = itc_trni.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itc_trni.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itc_trni.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itc_trni_cnt.whse_code           = itc_trni.whse_code
                    AND    itc_trni_cnt.doc_id              = itc_trni.doc_id
                    AND    itc_trni_cnt.itc_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"XFER"�i�ϑ�����ړ��j�̒��o
                    UNION ALL  -- �����^�C�v"XFER"�i�ϑ�����ړ��j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_xfer.whse_code
                          ,itp_xfer.location
                          ,itp_xfer.item_id
                          ,itp_xfer.lot_id
                          ,itp_xfer.trans_date
                          ,itp_xfer.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- �󕥋敪���VIEW_�q�Ɋ֘A
                          ,ic_tran_pnd               itp_xfer   -- OPM�ۗ��݌Ƀg�����U�N�V����
                          ,ic_xfer_mst               ixm_xfer   -- OPM�݌ɓ]���}�X�^
                          ,xxinv_mov_req_instr_lines xmril_xfer -- �ړ��˗�/�w�����ׁi�A�h�I���j
                          ,( SELECT itp_b.whse_code
                                   ,itp_b.doc_id
                                   ,COUNT(*)      AS itp_cnt
                             FROM   ic_tran_pnd      itp_b      -- OPM�ۗ��݌Ƀg�����U�N�V����
                             WHERE  itp_b.doc_type          = gc_doc_type_xfer
                             AND    itp_b.completed_ind     = gc_completed_ind_1
                             GROUP BY itp_b.whse_code
                                     ,itp_b.doc_id
                           )                         itp_xfer_cnt
                    WHERE  itp_xfer.doc_type                = gc_doc_type_xfer
                    AND    itp_xfer.completed_ind           = gc_completed_ind_1
                    AND    xrpm9v.doc_type                  = gc_doc_type_xfer
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    TO_NUMBER( ixm_xfer.attribute1 ) = xmril_xfer.mov_line_id
                    AND    itp_xfer.doc_id                  = ixm_xfer.transfer_id
                    AND    xrpm9v.doc_type                  = itp_xfer.doc_type
                    AND    xrpm9v.reason_code               = itp_xfer.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itp_xfer.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itp_xfer.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itp_xfer_cnt.whse_code           = itp_xfer.whse_code
                    AND    itp_xfer_cnt.doc_id              = itp_xfer.doc_id
                    AND    itp_xfer_cnt.itp_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"OMSO"�i�󒍁j�̒��o
                    UNION ALL  -- �����^�C�v"OMSO"�i�󒍁j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_omso.whse_code
                          ,itp_omso.location
                          ,itp_omso.item_id
                          ,itp_omso.lot_id
                          ,itp_omso.trans_date
                          ,itp_omso.trans_qty
                          ,xrpm7v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst7_v      xrpm7v     -- �󕥋敪���VIEW_OMSO
                          ,ic_tran_pnd               itp_omso   -- OPM�ۗ��݌Ƀg�����U�N�V����
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                          ,ic_lots_mst               ilm_omso   -- OPM���b�g�}�X�^
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                    WHERE  itp_omso.doc_type                = gc_doc_type_omso
                    AND    itp_omso.completed_ind           = gc_completed_ind_1
                    AND    xrpm7v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm7v.doc_type                  = itp_omso.doc_type
                    AND    xrpm7v.line_id                   = itp_omso.line_id
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                    AND    xrpm7v.lot_number                = ilm_omso.lot_no
                    AND    itp_omso.item_id                 = ilm_omso.item_id
                    AND    itp_omso.lot_id                  = ilm_omso.lot_id
-- 08/07/08 Y.Yamamoto ADD v1.14 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"PROD"�i���Y�j�̒��o
                    UNION ALL  -- �����^�C�v"PROD"�i���Y�j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_prod.whse_code
                          ,itp_prod.location
                          ,itp_prod.item_id
                          ,itp_prod.lot_id
                          ,itp_prod.trans_date
                          ,itp_prod.trans_qty
                          ,xrpm2v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst2_v      xrpm2v     -- �󕥋敪���VIEW���Y
                          ,ic_tran_pnd               itp_prod   -- OPM�ۗ��݌Ƀg�����U�N�V����
                    WHERE  itp_prod.doc_type                = gc_doc_type_prod
                    AND    itp_prod.completed_ind           = gc_completed_ind_1
                    AND    xrpm2v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm2v.doc_type                  = itp_prod.doc_type
                    AND    xrpm2v.doc_id                    = itp_prod.doc_id
                    AND    xrpm2v.doc_line                  = itp_prod.doc_line
                    AND    xrpm2v.line_type                 = itp_prod.line_type
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����^�C�v"PORC"�i�����j�̒��o
                    UNION ALL  -- �����^�C�v"PORC"�i�����j�̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_porc.whse_code
                          ,itp_porc.location
                          ,itp_porc.item_id
                          ,itp_porc.lot_id
                          ,itp_porc.trans_date
                          ,itp_porc.trans_qty
                          ,xrpm8v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- �O�����݌ɐ�
                          ,0  AS cargo_stock_be                 -- �O���ϑ����݌ɐ�
                          ,0  AS month_stock_nw                 -- �������݌ɐ�
                          ,0  AS cargo_stock_nw                 -- �����ϑ����݌ɐ�
                          ,0  AS case_amt                       -- �I���P�[�X��
                          ,0  AS loose_amt                      -- �I���o��
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst8_v      xrpm8v     -- �󕥋敪���VIEW_PORC
                          ,ic_tran_pnd               itp_porc   -- OPM�ۗ��݌Ƀg�����U�N�V����
                    WHERE  itp_porc.doc_type                = gc_doc_type_porc
                    AND    itp_porc.completed_ind           = gc_completed_ind_1
                    AND    xrpm8v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm8v.doc_type                  = itp_porc.doc_type
                    AND    xrpm8v.doc_id                    = itp_porc.doc_id
                    AND    xrpm8v.doc_line                  = itp_porc.doc_line
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �O�����݌ɂ̒��o
                    UNION ALL  -- �O�����݌ɂ̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_be.whse_code
                          ,xilv_be.segment1                        AS location
                          ,xsims_be.item_id
                          ,xsims_be.lot_id
                          ,gd_date_ym_first      AS trans_date       -- �O���̃f�[�^�Ȃ̂Ō������邽��
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,SUM( NVL( xsims_be.monthly_stock, 0 ) ) AS month_stock_be  -- �����݌ɐ�
                          ,SUM( NVL( xsims_be.cargo_stock,   0 ) ) AS cargo_stock_be  -- �ϑ����݌ɐ�
                          ,0                     AS month_stock_nw   -- �������݌ɐ�
                          ,0                     AS cargo_stock_nw   -- �����ϑ����݌ɐ�
                          ,0                     AS case_amt         -- �I���P�[�X��
                          ,0                     AS loose_amt        -- �I���o��
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_be   -- �I�������݌Ƀe�[�u��
                          ,xxcmn_item_locations_v xilv_be
                    WHERE  xsims_be.invent_ym = gv_date_ym_before    -- �I���N���O���̂���
                    AND    xilv_be.whse_code = xsims_be.whse_code
                    AND    xilv_be.segment1 = ( SELECT MIN( x.segment1 )
                                                FROM   xxcmn_item_locations_v x
                                                WHERE  x.whse_code = xsims_be.whse_code )
                    GROUP BY xsims_be.whse_code                      -- �q�ɃR�[�h
                            ,xilv_be.segment1
                            ,xsims_be.item_id                        -- �i��ID
                            ,xsims_be.lot_id                         -- ���b�gID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �����݌ɂ̒��o
                    UNION ALL  -- �����݌ɂ̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_nw.whse_code
                          ,xilv_nw.segment1                        AS location
                          ,xsims_nw.item_id
                          ,xsims_nw.lot_id
                          ,gd_date_ym_first      AS trans_date       -- �������邽��
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- �����݌ɐ�
                          ,0                     AS cargo_stock_be   -- �ϑ����݌ɐ�
                          ,SUM( NVL( xsims_nw.monthly_stock, 0 ) ) AS month_stock_nw  -- �������݌ɐ�
                          ,SUM( NVL( xsims_nw.cargo_stock,   0 ) ) AS cargo_stock_nw  -- �����ϑ����݌ɐ�
                          ,0                     AS case_amt         -- �I���P�[�X��
                          ,0                     AS loose_amt        -- �I���o��
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_nw   -- �I�������݌Ƀe�[�u��
                          ,xxcmn_item_locations_v xilv_nw
                    WHERE  xsims_nw.invent_ym = TO_CHAR( gd_date_ym_first, gc_char_ym_format ) -- �I���N�������̂���
                    AND    xilv_nw.whse_code = xsims_nw.whse_code
                    AND    xilv_nw.segment1 = ( SELECT MIN( y.segment1 )
                                                FROM   xxcmn_item_locations_v y
                                                WHERE  y.whse_code = xsims_nw.whse_code )
                    GROUP BY xsims_nw.whse_code                      -- �q�ɃR�[�h
                            ,xilv_nw.segment1
                            ,xsims_nw.item_id                        -- �i��ID
                            ,xsims_nw.lot_id                         -- ���b�gID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- �I�����ʏ��̒��o
                    UNION ALL  -- �I�����ʏ��̒��o
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsir.invent_whse_code AS whse_code
                          ,xilv_sir.segment1                       AS location
                          ,xsir.item_id
-- 08/05/09 Y.Yamamoto Update v1.3 Start
--                          ,xsir.lot_id
                          ,NVL( xsir.lot_id, 0 ) AS lot_id
-- 08/05/09 Y.Yamamoto Update v1.3 End
                          ,gd_date_ym_first      AS trans_date       -- �������邽��
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- �����݌ɐ�
                          ,0                     AS cargo_stock_be   -- �ϑ����݌ɐ�
                          ,0                     AS month_stock_nw   -- �������݌ɐ�
                          ,0                     AS cargo_stock_nw   -- �����ϑ����݌ɐ�
                          ,SUM( xsir.case_amt )  AS case_amt         -- �I���P�[�X��
                          ,SUM( xsir.loose_amt ) AS loose_amt        -- �I���o��
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- �g�����U�N�V�����n�f�[�^�̒��o�m�F�p
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_result xsir                     -- �I�����ʃe�[�u��
                          ,xxcmn_item_locations_v xilv_sir
                    WHERE  xsir.invent_date      BETWEEN gd_date_ym_first      -- �p�����[�^�̑Ώ۔N���̂P������
                                                 AND     gd_date_ym_last       -- �������Ŏ擾
                    AND    xilv_sir.whse_code = xsir.invent_whse_code
                    AND    xilv_sir.segment1 = ( SELECT MIN( z.segment1 )
                                                 FROM   xxcmn_item_locations_v z
                                                 WHERE  z.whse_code = xsir.invent_whse_code )
                    GROUP BY xsir.invent_whse_code                             -- �I���q��
                            ,xilv_sir.segment1
                            ,xsir.item_id                                      -- �i��ID
                            ,xsir.lot_id                                       -- ���b�gID
-- 08/05/07 Y.Yamamoto ADD v1.1 End
                  ) xrpmv
           )                                         xrpm       -- �݌Ƀg�������
-- 08/05/20 mod v1.5 start
--          ,( SELECT DISTINCT    ccd.item_id
--             FROM   cm_cmpt_dtl ccd
           ,(SELECT distinct item_id,cost_manage_code
             FROM (
               --�W��
               SELECT ccd.item_id,gc_cost_manage_code_hyozyun cost_manage_code
               FROM   cm_cmpt_dtl ccd
                     ,xxcmn_item_mst2_v ximv
               WHERE nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) = gc_cost_manage_code_hyozyun
               AND ccd.item_id = ximv.item_id
               --�W���ȊO
               union all
               SELECT ximv.item_id,gc_cost_manage_code_jissei cost_manage_code
               FROM   xxcmn_item_mst2_v ximv
               WHERE  nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) != gc_cost_manage_code_hyozyun
             )
-- 08/05/20 mod v1.5 end
           )                                         ccd_item        -- �i�ڌ����}�X�^
    WHERE  ccd_item.item_id             = ximv.item_id
-- 08/05/20 add v1.5 start
    AND    DECODE(ximv.cost_manage_code
                   ,gc_cost_manage_code_hyozyun,gc_cost_manage_code_hyozyun
                                               ,gc_cost_manage_code_jissei) = ccd_item.cost_manage_code
-- 08/05/20 add v1.5 end
    AND    xicv.item_id                 = ximv.item_id
    AND    ilm.item_id                  = ximv.item_id
    AND    gd_date_ym_first       BETWEEN ximv.start_date_active
                                      AND ximv.end_date_active
    AND    xicv.prod_class_code         = in_item_class
    AND    xicv.item_class_code         = in_item_div
    AND    gd_date_ym_first       BETWEEN xilv.date_from
                                      AND NVL( xilv.date_to, gd_max_date )
    -- ��������݌Ƀg�����Ƃ̌���
    AND    xrpm.whse_code               = xilv.whse_code
    AND  ( xrpm.location                = xilv.segment1
-- 08/05/08 Y.Yamamoto Update v1.1 Start
--        OR xrpm.lot_id                  = 0 )
        OR (ximv.lot_ctl                = 0
          AND xilv.segment1 = ( SELECT MIN( zz.segment1 )
                                FROM   xxcmn_item_locations_v zz
                                WHERE  zz.whse_code = xilv.whse_code ) ) )
-- 08/05/08 Y.Yamamoto Update v1.1 End
    AND    xrpm.item_id                 = ximv.item_id
    AND    xrpm.lot_id                  = ilm.lot_id
    AND    xrpm.trans_date        BETWEEN gd_date_ym_first
                                      AND gd_date_ym_last
    -- ��������p�����[�^�����Ƃ̌���
--mod start 2.2
/*
    AND (((( xilv.whse_code             = in_whse_code1  )
      OR  (  xilv.whse_code             = in_whse_code2  )
      OR  (  xilv.whse_code             = in_whse_code3  ) )
     OR  ((  xilv.distribution_block    = in_block_code1 )
      OR  (  xilv.distribution_block    = in_block_code2 )
      OR  (  xilv.distribution_block    = in_block_code3 ) ) )
     OR   (  in_whse_code1  IS NULL AND in_whse_code2  IS NULL AND in_whse_code3  IS NULL
         AND in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL ) )
-- 08/05/09 Y.Yamamoto Update v1.2 Start
--    AND  ((( in_whse_dept1             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept1 ) )
--     AND ( ( in_whse_dept2             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept2 ) )
--     AND ( ( in_whse_dept3             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
--    AND  ((( in_item_no1               IS NULL )
--        OR ( ximv.item_no               = in_item_no1 ) )
--     AND ( ( in_item_no2               IS NULL )
--        OR ( ximv.item_no               = in_item_no2 ) )
--     AND ( ( in_item_no3               IS NULL )
--        OR ( ximv.item_no               = in_item_no3 ) ) )
--    AND  ((( in_lot_no1                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no1 ) )
--     AND ( ( in_lot_no2                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no2 ) )
--     AND ( ( in_lot_no3                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
--    AND  ((( in_create_date1           IS NULL )
--        OR ( ilm.attribute1             = in_create_date1 ) )
--     AND ( ( in_create_date2           IS NULL )
--        OR ( ilm.attribute1             = in_create_date2 ) )
--     AND ( ( in_create_date3           IS NULL )
--        OR ( ilm.attribute1             = in_create_date3 ) ) )
    AND  ((( in_whse_dept1             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept1 ) )
     OR  ( ( in_whse_dept2             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept2 ) )
     OR  ( ( in_whse_dept3             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
    AND  ((( in_item_no1               IS NULL )
        OR ( ximv.item_no               = in_item_no1 ) )
     OR  ( ( in_item_no2               IS NULL )
        OR ( ximv.item_no               = in_item_no2 ) )
     OR  ( ( in_item_no3               IS NULL )
        OR ( ximv.item_no               = in_item_no3 ) ) )
    AND  ((( in_lot_no1                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no1 ) )
     OR  ( ( in_lot_no2                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no2 ) )
     OR  ( ( in_lot_no3                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
    AND  ((( in_create_date1           IS NULL )
        OR ( ilm.attribute1             = in_create_date1 ) )
     OR  ( ( in_create_date2           IS NULL )
        OR ( ilm.attribute1             = in_create_date2 ) )
     OR  ( ( in_create_date3           IS NULL )
        OR ( ilm.attribute1             = in_create_date3 ) ) )
-- 08/05/09 Y.Yamamoto Update v1.2 End
*/
    --�q�ɊǗ������ɂ��i����
    AND (in_whse_dept1 IS NULL AND in_whse_dept2 IS NULL AND in_whse_dept3 IS NULL
      OR xilv.whse_department IN (in_whse_dept1,in_whse_dept2,in_whse_dept3)
    )
    --�q�ɃR�[�h�ɂ��i����
    AND (in_whse_code1 IS NULL AND in_whse_code2 IS NULL AND in_whse_code3 IS NULL
      OR xilv.whse_code IN (in_whse_code1,in_whse_code2,in_whse_code3)
    )
    --�����u���b�N�ɂ��i����
    AND (in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL
      OR xilv.distribution_block IN (in_block_code1,in_block_code2,in_block_code3)
    )
    --�i�ڃR�[�h�ɂ��i����
    AND (in_item_no1 IS NULL AND in_item_no2 IS NULL AND in_item_no3 IS NULL
      OR ximv.item_no IN (in_item_no1,in_item_no2,in_item_no3)
    )
    --�����N�����ɂ��i����
    AND (in_create_date1 IS NULL AND in_create_date2 IS NULL AND in_create_date3 IS NULL
      OR ilm.attribute1 IN (in_create_date1,in_create_date2,in_create_date3)
    )
    --���b�gNo�ɂ��i����
    AND (in_lot_no1 IS NULL AND in_lot_no2 IS NULL AND in_lot_no3 IS NULL
      OR ilm.lot_no IN (in_lot_no1,in_lot_no2,in_lot_no3)
    )
--mod end 2.2
    GROUP BY  xilv.whse_code                                                 -- �q�ɃR�[�h
             ,ximv.item_id                                                   -- �i��ID
             ,ximv.item_no                                                   -- �i�ڃR�[�h
             ,ilm.lot_no                                                     -- ���b�gNo
             ,ilm.lot_id                                                     -- ���b�gID
             ,ilm.attribute1                                                 -- �����N����
             ,ilm.attribute3                                                 -- �ܖ�����
             ,ilm.attribute2                                                 -- �ŗL�L��
             ,ximv.item_um                                                   -- �P��
             ,ximv.conv_unit                                                 -- ���o�Ɋ��Z�P��
-- 08/05/21 v1.7 start
    HAVING NOT (     SUM( NVL(xrpm.month_stock_be,0 )) = 0                   -- �O�����݌ɐ�
                 AND SUM( NVL(xrpm.cargo_stock_be,0 )) = 0                   -- �O���ϑ����݌ɐ�
                 AND SUM( NVL(xrpm.month_stock_nw,0 )) = 0                   -- �������݌ɐ�
                 AND SUM( NVL(xrpm.cargo_stock_nw,0 )) = 0                   -- �����ϑ����݌ɐ�
                 AND SUM( NVL(xrpm.case_amt,0  )) = 0                        -- �I���P�[�X��
                 AND SUM( NVL(xrpm.loose_amt,0 )) = 0                        -- �I���o��
-- 08/07/08 Y.Yamamoto Update v1.14 Start
--                 AND SUM( NVL(xrpm.stock_quantity,0)) = 0                    -- ������ʁi���ɐ��j
--                 AND SUM( NVL(xrpm.leaving_quantity,0)) = 0                  -- ������ʁi�o�ɐ��j
--               )
               )
               OR SUM( NVL(xrpm.trans_cnt,0)) > 0                            -- �g�����n�̃f�[�^������Ƃ���0����
-- 08/07/08 Y.Yamamoto Update v1.14 End
-- 08/05/21 v1.7 end
    ORDER BY xilv.whse_code                                                  -- �q�ɃR�[�h
             ,ximv.item_no                                                   -- �i�ڃR�[�h
             ,ilm.lot_no                                                     -- ���b�gNo
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    IF (  ir_param.iv_item_div = gc_item_div_seihin ) THEN
      -- �J�[�\���I�[�v��
      -- �i�ڋ敪�i���i�j
      OPEN cur_main_data_seihin
        (
          ir_param.iv_whse_dept1          -- �q�ɊǗ�����1
         ,ir_param.iv_whse_dept2          -- �q�ɊǗ�����2
         ,ir_param.iv_whse_dept3          -- �q�ɊǗ�����3
         ,ir_param.iv_whse_code1          -- �q�ɃR�[�h1
         ,ir_param.iv_whse_code2          -- �q�ɃR�[�h2
         ,ir_param.iv_whse_code3          -- �q�ɃR�[�h3
         ,ir_param.iv_block_code1         -- �u���b�N1
         ,ir_param.iv_block_code2         -- �u���b�N2
         ,ir_param.iv_block_code3         -- �u���b�N3
         ,ir_param.iv_item_class          -- ���i�敪
         ,ir_param.iv_um_class            -- �P��
         ,ir_param.iv_item_div            -- �i�ڋ敪
         ,ir_param.iv_item_no1            -- �i�ڃR�[�h1
         ,ir_param.iv_item_no2            -- �i�ڃR�[�h2
         ,ir_param.iv_item_no3            -- �i�ڃR�[�h3
         ,ir_param.iv_create_date1        -- �����N����1
         ,ir_param.iv_create_date2        -- �����N����2
         ,ir_param.iv_create_date3        -- �����N����3
         ,ir_param.iv_lot_no1             -- ���b�gNo1
         ,ir_param.iv_lot_no2             -- ���b�gNo2
         ,ir_param.iv_lot_no3             -- ���b�gNo3
        ) ;
      -- �o���N�t�F�b�`
      FETCH cur_main_data_seihin BULK COLLECT INTO ot_data_rec ;
      -- �J�[�\���N���[�Y
      CLOSE cur_main_data_seihin ;
    ELSE
      -- �i�ڋ敪�i���i�j�ȊO
      -- �J�[�\���I�[�v��
      OPEN cur_main_data_etc
        (
          ir_param.iv_whse_dept1          -- �q�ɊǗ�����1
         ,ir_param.iv_whse_dept2          -- �q�ɊǗ�����2
         ,ir_param.iv_whse_dept3          -- �q�ɊǗ�����3
         ,ir_param.iv_whse_code1          -- �q�ɃR�[�h1
         ,ir_param.iv_whse_code2          -- �q�ɃR�[�h2
         ,ir_param.iv_whse_code3          -- �q�ɃR�[�h3
         ,ir_param.iv_block_code1         -- �u���b�N1
         ,ir_param.iv_block_code2         -- �u���b�N2
         ,ir_param.iv_block_code3         -- �u���b�N3
         ,ir_param.iv_item_class          -- ���i�敪
         ,ir_param.iv_um_class            -- �P��
         ,ir_param.iv_item_div            -- �i�ڋ敪
         ,ir_param.iv_item_no1            -- �i�ڃR�[�h1
         ,ir_param.iv_item_no2            -- �i�ڃR�[�h2
         ,ir_param.iv_item_no3            -- �i�ڃR�[�h3
         ,ir_param.iv_create_date1        -- �����N����1
         ,ir_param.iv_create_date2        -- �����N����2
         ,ir_param.iv_create_date3        -- �����N����3
         ,ir_param.iv_lot_no1             -- ���b�gNo1
         ,ir_param.iv_lot_no2             -- ���b�gNo2
         ,ir_param.iv_lot_no3             -- ���b�gNo3
        ) ;
      -- �o���N�t�F�b�`
      FETCH cur_main_data_etc BULK COLLECT INTO ot_data_rec ;
      -- �J�[�\���N���[�Y
      CLOSE cur_main_data_etc ;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_main_data_seihin%ISOPEN THEN
        CLOSE cur_main_data_seihin ;
      END IF ;
      IF cur_main_data_etc%ISOPEN THEN
        CLOSE cur_main_data_etc ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_main_data_seihin%ISOPEN THEN
        CLOSE cur_main_data_seihin ;
      END IF ;
      IF cur_main_data_etc%ISOPEN THEN
        CLOSE cur_main_data_etc ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_main_data_seihin%ISOPEN THEN
        CLOSE cur_main_data_seihin ;
      END IF ;
      IF cur_main_data_etc%ISOPEN THEN
        CLOSE cur_main_data_etc ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(A-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data IN OUT NOCOPY XML_DATA
     ,ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_break_init          VARCHAR2(5)  := '*****';
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_loc_code            mtl_item_locations.segment1%TYPE;                   -- ���ɑq�ɃR�[�h
    lv_item_no_key         ic_item_mst_b.item_no%TYPE;                         -- �i�ڃR�[�h
--
    -- �Ώی��x�̏o�͕ҏW�p
    lv_date_ym             VARCHAR2(12);
    -- �o�͕ҏW�p
    lv_whse_name           ic_whse_mst.whse_name%TYPE;                         -- �q�ɖ�
    lv_item_k_name         mtl_categories_tl.description%TYPE;                 -- �i�ڋ敪����
    lv_item_short_name     xxcmn_item_mst_b.item_short_name%TYPE;              -- �i�ڗ���
    ln_lot_ctl             ic_item_mst_b.lot_ctl%TYPE;                         -- ���b�g�Ǘ��敪
    lv_last_item_um        ic_item_mst_b.attribute24%TYPE;                     -- �Ō�̃f�[�^�̒P��
--add start 2.0
    lv_prev_lot_ctl        VARCHAR2(10);                                       -- �O���R�[�h�̃��b�g�Ǘ��敪
--add end 2.0
--
    -- �v�Z�p�A�\���p���l����
    ln_loct_onhand         ic_loct_inv.loct_onhand%TYPE;                       -- �莝�萔��
-- 08/05/07 Y.Yamamoto Delete v1.1 Start
--    ln_month_stock_nw      xxinv_stc_inventory_month_stck.monthly_stock%TYPE;  -- �������݌�
--    ln_cargo_stock_nw      xxinv_stc_inventory_month_stck.cargo_stock%TYPE;    -- �������ϑ����݌�
--    ln_month_stock_be      xxinv_stc_inventory_month_stck.monthly_stock%TYPE;  -- �O�����݌�
--    ln_cargo_stock_be      xxinv_stc_inventory_month_stck.cargo_stock%TYPE;    -- �O�����ϑ����݌�
--    ln_case_amt            xxinv_stc_inventory_result.case_amt%TYPE;           -- �I���P�[�X��
--    ln_loose_amt           xxinv_stc_inventory_result.loose_amt%TYPE;          -- �I���o��
-- 08/05/07 Y.Yamamoto Delete v1.1 End
    ln_quantity            NUMBER;                                             -- ����
    ln_month_start_stock   NUMBER;                                             -- �����݌ɐ�
    ln_stock_quantity      NUMBER;                                             -- �������ɐ�
    ln_leaving_quantity    NUMBER;                                             -- �����o�ɐ�
    ln_logic_month_stock   NUMBER;                                             -- �_�������݌ɐ�
    ln_invent_month_stock  NUMBER;                                             -- ���I�����݌ɐ�
    ln_invent_cargo_stock  NUMBER;                                             -- ���I�ϑ��݌ɐ�
    ln_month_stock         NUMBER;                                             -- ���ِ�
    ln_stock_unit_price    NUMBER;                                             -- �݌ɒP��
    ln_logic_stock_amount  NUMBER;                                             -- �_���݌ɋ��z
    ln_invent_stock_amount NUMBER;                                             -- ���I�݌ɋ��z
    ln_month_stock_amount  NUMBER;                                             -- ���ً��z
    ln_num_of_cases        NUMBER;                                             -- �P�[�X����
    lv_cost_manage_code    ic_item_mst_b.attribute15%TYPE;                     -- �����Ǘ��敪
--
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    lv_data_out            VARCHAR2(1);                                        -- �o�͎��s�t���O
    lv_no_data_msg         VARCHAR2(5000) ;                                    --�u�f�[�^�͂���܂���v
-- 08/05/09 Y.Yamamoto ADD v1.2 End
    -- *** ���[�J���E��O���� ***
    no_data_expt   EXCEPTION ;   -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
    -- =====================================================
    -- �u���C�N�L�[������
    -- =====================================================
    lv_loc_code    := lc_break_init;
    lv_item_no_key := lc_break_init;
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    -- =====================================================
    -- ������
    -- =====================================================
    lv_data_out    := '0';
-- 08/05/09 Y.Yamamoto ADD v1.2 End
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- =====================================================
    -- �i�ڋ敪�i���́j�擾
    -- =====================================================
    BEGIN
      SELECT SUBSTRB( MAX( xicv.description ), 1, 6 )
      INTO   lv_item_k_name
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.segment1          = ir_param.iv_item_div
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_item_k_name := NULL ;
    END ;
--
    -- -----------------------------------------------------
    -- �f�[�^�f�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'root',      NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �q�ɂf�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- ���[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- ���[�h�c
    insert_xml_plsql_table(iox_xml_data, 'report_id', gc_report_id, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- ���{��
    insert_xml_plsql_table(iox_xml_data, 'exec_date', TO_CHAR( gd_exec_date, gc_char_dt_format ), 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �Ώی��x
    -- �Ώی��x�̕ҏW
    lv_date_ym := TO_CHAR( gd_date_ym_first, gc_char_ym_out_format );
    insert_xml_plsql_table(iox_xml_data, 'date_ym', lv_date_ym, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �S������
    insert_xml_plsql_table(iox_xml_data, 'department_code', gv_department_code, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �S����
    insert_xml_plsql_table(iox_xml_data, 'department_name', gv_department_name, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �i�ڋ敪�i�R�[�h�j
    insert_xml_plsql_table(iox_xml_data, 'item_div_code', ir_param.iv_item_div, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �i�ڋ敪�i���́j
    insert_xml_plsql_table(iox_xml_data, 'item_div_name', lv_item_k_name, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- ���[�f�f�[�^�I���^�O
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- �R�t���f�[�^�擾
      -- =====================================================
      -- �i�ڗ��̂̎擾
      BEGIN
        SELECT ximv.item_short_name                                -- �i�ڗ���
              ,ximv.lot_ctl                                        -- ���b�g�Ǘ��敪
        INTO   lv_item_short_name
              ,ln_lot_ctl
        FROM   xxcmn_item_mst2_v  ximv                             -- OPM�i�ڏ��VIEW2
        WHERE  ximv.item_id     = gt_main_data(i).item_id
        AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                AND     ximv.end_date_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_item_short_name := NULL;
          ln_lot_ctl         := 0;
      END;
--
      -- �莝����
      BEGIN
        SELECT SUM( ili.loct_onhand ) loct_onhand                  -- �莝����
        INTO   ln_loct_onhand
        FROM   ic_loct_inv ili                                     -- OPM�莝����
        WHERE  ili.item_id   = gt_main_data(i).item_id
        AND    ili.whse_code = gt_main_data(i).whse_code
        AND    ili.lot_id    = gt_main_data(i).lot_id
        GROUP BY ili.item_id                                       -- �i��ID
                ,ili.whse_code                                     -- �q�ɃR�[�h
                ,ili.lot_id                                        -- ���b�gID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_loct_onhand := 0;
      END;
--
-- 08/05/07 Y.Yamamoto Delete v1.1 Start
      -- �O�����݌�
--      BEGIN
--        SELECT SUM( NVL( xsims.monthly_stock, 0 ) ) monthly_stock  -- �����݌ɐ�
--              ,SUM( NVL( xsims.cargo_stock,   0 ) )   cargo_stock  -- �ϑ����݌ɐ�
--        INTO   ln_month_stock_be
--              ,ln_cargo_stock_be
--        FROM   xxinv_stc_inventory_month_stck xsims                -- �I�������݌Ƀe�[�u��
--        WHERE  xsims.whse_code = gt_main_data(i).whse_code
--        AND    xsims.item_id   = gt_main_data(i).item_id
--        AND   (   xsims.lot_id IS NULL
--               OR xsims.lot_id = gt_main_data(i).lot_id )
--        AND    xsims.invent_ym = gv_date_ym_before                 -- �I���N���O���̂���
--        GROUP BY xsims.item_id                                     -- �i��ID
--                ,xsims.whse_code                                   -- �q�ɃR�[�h
--                ,xsims.lot_id                                      -- ���b�gID
--                ,xsims.invent_ym                                   -- �I���N��
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_month_stock_be := 0;
--          ln_cargo_stock_be := 0;
--      END;
--
      -- �����݌�
--      BEGIN
--        SELECT SUM( NVL( xsims.monthly_stock, 0 ) ) monthly_stock  -- �����݌ɐ�
--              ,SUM( NVL( xsims.cargo_stock,   0 ) )   cargo_stock  -- �ϑ����݌ɐ�
--        INTO   ln_month_stock_nw
--              ,ln_cargo_stock_nw
--        FROM   xxinv_stc_inventory_month_stck xsims                -- �I�������݌Ƀe�[�u��
--        WHERE  xsims.whse_code = gt_main_data(i).whse_code
--        AND    xsims.item_id   = gt_main_data(i).item_id
--        AND   (   xsims.lot_id IS NULL
--               OR xsims.lot_id = gt_main_data(i).lot_id )
--        AND    xsims.invent_ym = ir_param.iv_date_ym               -- �I���N�������̂���
--        GROUP BY xsims.item_id                                     -- �i��ID
--                ,xsims.whse_code                                   -- �q�ɃR�[�h
--                ,xsims.lot_id                                      -- ���b�gID
--                ,xsims.invent_ym                                   -- �I���N��
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_month_stock_nw := 0;
--          ln_cargo_stock_nw := 0;
--      END;
--
      -- �I�����ʏ�� �f�[�^���擾�ł��Ȃ��Ƃ��͂O
--      BEGIN
--        SELECT SUM( xsir.case_amt )  case_amt                      -- �I���P�[�X��
--              ,SUM( xsir.loose_amt ) loose_amt                     -- �I���o��
--        INTO   ln_case_amt 
--              ,ln_loose_amt
--        FROM   xxinv_stc_inventory_result xsir                     -- �I�����ʃe�[�u��
--        WHERE  xsir.invent_whse_code = gt_main_data(i).whse_code
--        AND    xsir.item_id          = gt_main_data(i).item_id
--        AND    xsir.lot_id           = gt_main_data(i).lot_id
--        AND    xsir.invent_date      BETWEEN gd_date_ym_first      -- �p�����[�^�̑Ώ۔N���̂P������
--                                     AND     gd_date_ym_last       -- �������Ŏ擾
--        GROUP BY xsir.item_id                                      -- �i��ID
--                ,xsir.invent_whse_code                             -- �I���q��
--                ,xsir.lot_id                                       -- ���b�gID
--      ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_case_amt  := 0;
--          ln_loose_amt := 0;
--      END;
-- 08/05/07 Y.Yamamoto Delete v1.1 End
--
      -- -----------------------------------------------------
      -- �敪���׌v�Z����
      -- -----------------------------------------------------
      -- ����
      BEGIN
        IF (    ir_param.iv_item_div = gc_item_div_seihin ) THEN
          -- �i�ڋ敪�i���i�j
          SELECT TO_NUMBER( NVL( ximv.num_of_cases, '0' ) )          -- �P�[�X����
          INTO   ln_quantity
          FROM   xxcmn_item_mst2_v  ximv                             -- OPM�i�ڏ��VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        ELSIF ( ir_param.iv_item_div = gc_item_div_hanseihin ) 
           OR ( ir_param.iv_item_div = gc_item_div_genryo ) THEN
          -- �i�ڋ敪�i�����i�j�������́A�i�ڋ敪�i�����j
          SELECT TO_NUMBER( NVL( ilm.attribute6, '0' ) )             -- �݌ɓ���
          INTO   ln_quantity
          FROM   ic_lots_mst ilm
          WHERE  ilm.item_id = gt_main_data(i).item_id
          AND    ilm.lot_id  = gt_main_data(i).lot_id
          AND    ilm.lot_no  = gt_main_data(i).lot_no
          ;
        ELSIF ( ir_param.iv_item_div = gc_item_div_sizai ) THEN
          -- �i�ڋ敪�i���ށj
          SELECT TO_NUMBER( NVL( ximv.frequent_qty, '0' ) )          -- ��\����
          INTO   ln_quantity
          FROM   xxcmn_item_mst2_v  ximv                             -- OPM�i�ڏ��VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_quantity := 0;
      END;
--
      -- �����݌ɐ�
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- �P�ʋ敪�i�{���j
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--        ln_month_start_stock := ROUND( ln_month_stock_be + ln_cargo_stock_be, 3 );
        ln_month_start_stock := ROUND( gt_main_data(i).month_stock_be + gt_main_data(i).cargo_stock_be, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- �P�ʋ敪�i�P�[�X�j
        IF ( ln_quantity = 0 ) THEN
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_month_start_stock := ROUND( ( ln_month_stock_be + ln_cargo_stock_be ) / 1, 3 );
          ln_month_start_stock := ROUND( ( gt_main_data(i).month_stock_be + gt_main_data(i).cargo_stock_be ) / 1, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_month_start_stock := ROUND( ( ln_month_stock_be + ln_cargo_stock_be ) / ln_quantity, 3 );
          ln_month_start_stock := ROUND( ( gt_main_data(i).month_stock_be + gt_main_data(i).cargo_stock_be ) / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- �������ɐ�
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- �P�ʋ敪�i�{���j
        ln_stock_quantity := ABS( ROUND( gt_main_data(i).stock_quantity, 3 ) );
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- �P�ʋ敪�i�P�[�X�j
        IF ( ln_quantity = 0 ) THEN
          ln_stock_quantity := ABS( ROUND( gt_main_data(i).stock_quantity / 1, 3 ) );
        ELSE
          ln_stock_quantity := ABS( ROUND( gt_main_data(i).stock_quantity / ln_quantity, 3 ) );
        END IF;
      END IF;
--
      -- �����o�ɐ�
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- �P�ʋ敪�i�{���j
        ln_leaving_quantity := ABS( ROUND( gt_main_data(i).leaving_quantity, 3 ) );
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- �P�ʋ敪�i�P�[�X�j
        IF ( ln_quantity = 0 ) THEN
          ln_leaving_quantity := ABS( ROUND( gt_main_data(i).leaving_quantity / 1, 3 ) );
        ELSE
          ln_leaving_quantity := ABS( ROUND( gt_main_data(i).leaving_quantity / ln_quantity, 3 ) );
        END IF;
      END IF;
--
      -- �_�������݌ɐ�
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- �P�ʋ敪�i�{���j
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--        ln_logic_month_stock := ROUND( ln_month_stock_nw + ln_cargo_stock_nw, 3 );
        ln_logic_month_stock := ROUND( gt_main_data(i).month_stock_nw + gt_main_data(i).cargo_stock_nw, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- �P�ʋ敪�i�P�[�X�j
        IF ( ln_quantity = 0 ) THEN
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_logic_month_stock := ROUND( ( ln_month_stock_nw + ln_cargo_stock_nw ) / 1, 3 );
          ln_logic_month_stock := ROUND( ( gt_main_data(i).month_stock_nw + gt_main_data(i).cargo_stock_nw ) / 1, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_logic_month_stock := ROUND( ( ln_month_stock_nw + ln_cargo_stock_nw ) / ln_quantity, 3 );
          ln_logic_month_stock := ROUND( ( gt_main_data(i).month_stock_nw + gt_main_data(i).cargo_stock_nw ) / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- ���I�����݌ɐ�
      IF ( ln_quantity = 0 ) THEN
        BEGIN
-- 08/05/21 v1.8 mod start
--          SELECT ROUND( TO_NUMBER( NVL( ximv.num_of_cases, '0' ) ), 3 ) -- �P�[�X����
          SELECT ROUND( TO_NUMBER( NVL( ximv.num_of_cases, '1' ) ), 3 ) -- �P�[�X����
-- 08/05/21 v1.8 mod end
          INTO   ln_num_of_cases
          FROM   xxcmn_item_mst2_v  ximv                                -- OPM�i�ڏ��VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_num_of_cases := 0;
        END;
      END IF;
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- �P�ʋ敪�i�{���j
        IF ( ln_quantity = 0 ) THEN
-- 08/05/21 v1.8 mod start
--          ln_invent_month_stock := ln_num_of_cases;
          ln_invent_month_stock := ROUND( ( ln_num_of_cases * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt, 3 );
-- 08/05/21 v1.8 mod end
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_month_stock := ROUND( ( ln_quantity * ln_case_amt ) + ln_loose_amt, 3 );
          ln_invent_month_stock := ROUND( ( ln_quantity * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- �P�ʋ敪�i�P�[�X�j
        IF ( ln_quantity = 0 ) THEN
-- 08/05/21 v1.8 mod start
--          ln_invent_month_stock := ln_num_of_cases;
          ln_invent_month_stock := ROUND( ( ( ln_num_of_cases * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt )
                                                                          / ln_num_of_cases, 3 );
-- 08/05/21 v1.8 mod end
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_month_stock := ROUND( ( ( ln_quantity * ln_case_amt ) + ln_loose_amt )
--                                                                          / ln_quantity, 3 );
          ln_invent_month_stock := ROUND( ( ( ln_quantity * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt )
                                                                          / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- ���I�ϑ��݌ɐ�
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- �P�ʋ敪�i�{���j
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--        ln_invent_cargo_stock := ROUND( ln_cargo_stock_nw, 3 );
        ln_invent_cargo_stock := ROUND( gt_main_data(i).cargo_stock_nw, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- �P�ʋ敪�i�P�[�X�j
        IF ( ln_quantity = 0 ) THEN
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_cargo_stock := ROUND( ln_cargo_stock_nw / 1, 3 );
          ln_invent_cargo_stock := ROUND( gt_main_data(i).cargo_stock_nw / 1, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_cargo_stock := ROUND( ln_cargo_stock_nw / ln_quantity, 3 );
          ln_invent_cargo_stock := ROUND( gt_main_data(i).cargo_stock_nw / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- ���ِ�
      ln_month_stock := ROUND( ROUND( ln_logic_month_stock - ln_invent_month_stock, 3 )
                                                           - ln_invent_cargo_stock, 3 );
--
      -- �݌ɒP���A�݌ɋ��z�̎Z�o�i�O�����[�U�[�͍s��Ȃ��j
      IF ( gv_employee_div = gc_employee_div_out ) THEN
        ln_stock_unit_price    := NULL;                               -- �݌ɒP��
        ln_logic_stock_amount  := NULL;                               -- �_���݌ɋ��z
        ln_invent_stock_amount := NULL;                               -- ���I�݌ɋ��z
        ln_month_stock_amount  := NULL;                               -- ���ً��z
      ELSE
        -- �݌ɒP��
        BEGIN
          SELECT ximv.cost_manage_code                                -- �����Ǘ��敪
          INTO   lv_cost_manage_code
          FROM   xxcmn_item_mst2_v ximv                               -- OPM�i�ڏ��VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_cost_manage_code := 0;
        END;
--
        BEGIN
          IF (    lv_cost_manage_code = gc_cost_manage_code_hyozyun ) THEN
            -- �����Ǘ��敪�i�W���j
            SELECT ROUND( SUM( ccd.cmpnt_cost ), 2 )                    -- �R���|�[�l���g����
            INTO   ln_stock_unit_price
            FROM   cm_cmpt_dtl       ccd                                -- �i�ڌ����}�X�^
                  ,cm_cldr_dtl       ccld                               -- �����J�����_����
            WHERE  ccd.item_id        = gt_main_data(i).item_id
            AND    ccd.whse_code      = FND_PROFILE.VALUE(gc_cost_whse_code)
            AND    ccd.cost_mthd_code = FND_PROFILE.VALUE(gc_cost_div)
            AND    ccd.calendar_code  = ccld.calendar_code
            AND    ccd.period_code    = ccld.period_code
            AND    gd_date_ym_first   BETWEEN ccld.start_date
                                      AND     ccld.end_date
            GROUP BY ccd.item_id
            ;
          ELSIF ( lv_cost_manage_code = gc_cost_manage_code_jissei ) THEN
            -- �����Ǘ��敪�i�����j
            SELECT ROUND( TO_NUMBER( NVL( ilm.attribute7, '0' ) ), 2 )  -- �݌ɒP��
            INTO   ln_stock_unit_price
            FROM   ic_lots_mst ilm                                      -- OPM���b�g�}�X�^
            WHERE  ilm.item_id = gt_main_data(i).item_id
            AND    ilm.lot_id  = gt_main_data(i).lot_id
            AND    ilm.lot_no  = gt_main_data(i).lot_no
            ;
          ELSE
            ln_stock_unit_price := 0;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_stock_unit_price := 0;
        END;
--
        -- �_���݌ɋ��z
        ln_logic_stock_amount  := ROUND( ln_logic_month_stock  * ln_stock_unit_price );
--
        -- ���I�݌ɋ��z
        ln_invent_stock_amount := ROUND( ln_invent_month_stock * ln_stock_unit_price );
--
        -- ���ً��z
        ln_month_stock_amount  := ln_logic_stock_amount - ln_invent_stock_amount;
      END IF;
--
      IF  ( ir_param.iv_output_ctl = gc_output_ctl_all ) 
       OR ( ir_param.iv_output_ctl = gc_output_ctl_sel AND ln_month_stock <> 0 ) THEN
        -- ���ً敪�iALL�j�������͍��ً敪�i���ق�������́j�ō��ِ����������Ă�����̂��o��
        -- =====================================================
        -- ���ɑq�Ƀu���C�N
        -- =====================================================
        -- ���ɑq�ɂ��؂�ւ�����Ƃ�
        IF ( gt_main_data(i).whse_code <> lv_loc_code ) THEN
          -- -----------------------------------------------------
          -- ���ɑq�ɖ��ׂf�I���^�O�o��
          -- -----------------------------------------------------
          -- �ŏ��̃��R�[�h�̂Ƃ��͏o�͂��Ȃ�
          IF ( lv_loc_code <> lc_break_init ) THEN
            -- -----------------------------------------------------
            -- �P�ʊJ�n�^�O�o��
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, 'g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
            -- -----------------------------------------------------
            -- �P�ʃf�[�^�^�O�o��
            -- -----------------------------------------------------
            -- �P��
--mod start 1.9
--            insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( gt_main_data(i).item_um, 1, 4 ),
            insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( lv_last_item_um, 1, 4 ),
--mod end 1.9
                                                                gc_tag_type_data, gc_tag_value_type_char);
--add start 2.0
            -- -----------------------------------------------------
            -- ���b�g�Ǘ��敪�f�[�^�^�O�o��
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, 'lot_ctl', lv_prev_lot_ctl,
                                                                gc_tag_type_data, gc_tag_value_type_char);
--add end 2.0
            -- -----------------------------------------------------
            -- �P�ʏI���^�O�o��
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, '/g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
            -- -----------------------------------------------------
            -- �敪���ׂf�I���^�O�o��
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
            -- -----------------------------------------------------
            -- ���ɑq�ɖ��ׂf�I���^�O�o��
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, '/g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          END IF;
          -- -----------------------------------------------------
          -- ���ɑq�ɖ��ׂf�J�n�^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- ���ɑq�ɖ��ׂf�f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���ɑq�ɃR�[�h
          insert_xml_plsql_table(iox_xml_data, 'whse_code', SUBSTRB( gt_main_data(i).whse_code, 1, 4 ),
                                                              gc_tag_type_data, gc_tag_value_type_char);
--
          -- ���ɑq�ɖ��擾
          BEGIN
            SELECT SUBSTRB( MAX( xilv.whse_name ), 1, 20 )
            INTO   lv_whse_name
            FROM   xxcmn_item_locations2_v xilv
            WHERE  xilv.whse_code     = gt_main_data(i).whse_code
            AND    xilv.disable_date IS NULL
            AND    gd_date_ym_first  BETWEEN xilv.date_from
                                         AND NVL( xilv.date_to, gd_max_date )
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_whse_name := NULL;
          END;
--
          -- ���ɑq�ɐ於
          insert_xml_plsql_table(iox_xml_data, 'whse_name', lv_whse_name,
                                                              gc_tag_type_data, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- �敪���ׂf�J�n�^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- ���ɑq�Ƀu���C�N�L�[�X�V
          -- -----------------------------------------------------
          lv_loc_code := gt_main_data(i).whse_code;
          -- -----------------------------------------------------
          -- �i�ڃR�[�h�u���C�N�L�[�X�V
          -- -----------------------------------------------------
          lv_item_no_key := gt_main_data(i).item_no;
        END IF;
--
        -- =====================================================
        -- �i�ڃR�[�h�u���C�N
        -- =====================================================
        -- �i�ڃR�[�h���؂�ւ�����Ƃ�
        IF ( gt_main_data(i).item_no <> lv_item_no_key ) THEN
          -- -----------------------------------------------------
          -- �P�ʊJ�n�^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- �P�ʃf�[�^�^�O�o��
          -- -----------------------------------------------------
          -- �P��
--mod start 1.9
--          insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( gt_main_data(i).item_um, 1, 4 ),
          insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( lv_last_item_um, 1, 4 ),
--mod end 1.9
                                                              gc_tag_type_data, gc_tag_value_type_char);
--add start 2.0
          -- -----------------------------------------------------
          -- ���b�g�Ǘ��敪�f�[�^�^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'lot_ctl', lv_prev_lot_ctl,
                                                              gc_tag_type_data, gc_tag_value_type_char);
--add end 2.0
          -- -----------------------------------------------------
          -- �P�ʏI���^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, '/g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- �i�ږ��ׂf�I���^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- �i�ږ��ׂf�J�n�^�O�o��
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- �i�ڃR�[�h�u���C�N�L�[�X�V
          -- -----------------------------------------------------
          lv_item_no_key := gt_main_data(i).item_no;
        END IF;
--
        -- -----------------------------------------------------
        -- �敪���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- �敪���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �i�ځi�R�[�h�j
        insert_xml_plsql_table(iox_xml_data, 'item_code', SUBSTRB( TO_CHAR( gt_main_data(i).item_no ), 1, 7 ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �i�ځi���j
        insert_xml_plsql_table(iox_xml_data, 'item_name', lv_item_short_name, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���b�gNo
        IF ( ln_lot_ctl = gc_lot_ctl_1 ) THEN
          -- ���b�g�Ǘ��i
          insert_xml_plsql_table(iox_xml_data, 'lot_no', gt_main_data(i).lot_no, 
                                                              gc_tag_type_data, gc_tag_value_type_char);
        ELSE
          -- ���b�g��Ǘ��i
          insert_xml_plsql_table(iox_xml_data, 'lot_no', NULL, 
                                                              gc_tag_type_data, gc_tag_value_type_char);
        END IF;
        -- �����N����
        insert_xml_plsql_table(iox_xml_data, 'manufacture_date', gt_main_data(i).manufacture_date, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �ܖ�����
        insert_xml_plsql_table(iox_xml_data, 'expiration_date', gt_main_data(i).expiration_date, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �ŗL�L��
        insert_xml_plsql_table(iox_xml_data, 'uniqe_sign', gt_main_data(i).uniqe_sign, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
--
        -- ����
        insert_xml_plsql_table(iox_xml_data, 'quantity', TO_CHAR( ln_quantity ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �����݌ɐ�
        insert_xml_plsql_table(iox_xml_data, 'month_start_stock', TO_CHAR( ln_month_start_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �������ɐ�
        insert_xml_plsql_table(iox_xml_data, 'stock_quantity', TO_CHAR( ln_stock_quantity ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �����o�ɐ�
        insert_xml_plsql_table(iox_xml_data, 'leaving_quantity', TO_CHAR( ln_leaving_quantity ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
--
        -- �_�������݌ɐ�
        insert_xml_plsql_table(iox_xml_data, 'logic_month_stock', TO_CHAR( ln_logic_month_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���I�����݌ɐ�
        insert_xml_plsql_table(iox_xml_data, 'invent_month_stock', TO_CHAR( ln_invent_month_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���I�ϑ��݌ɐ�
        insert_xml_plsql_table(iox_xml_data, 'invent_cargo_stock', TO_CHAR( ln_invent_cargo_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���ِ�
        insert_xml_plsql_table(iox_xml_data, 'month_stock', TO_CHAR( ln_month_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
--
        -- �݌ɒP��
        insert_xml_plsql_table(iox_xml_data, 'stock_unit_price', TO_CHAR( ln_stock_unit_price ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- �_���݌ɋ��z
        insert_xml_plsql_table(iox_xml_data, 'logic_stock_amount', TO_CHAR( ln_logic_stock_amount ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���I�݌ɋ��z
        insert_xml_plsql_table(iox_xml_data, 'invent_stock_amount', TO_CHAR( ln_invent_stock_amount ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���ً��z
        insert_xml_plsql_table(iox_xml_data, 'month_stock_amount', TO_CHAR( ln_month_stock_amount ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- �敪���ׂf�I���^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, '/g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
        -- =====================================================
        -- ���ׂ̃f�[�^���o�͂����̂Ńt���OON
        -- =====================================================
        lv_data_out := '1';
-- 08/05/09 Y.Yamamoto ADD v1.2 End
      END IF;
--
      -- -----------------------------------------------------
      -- �P�ʕۑ�
      -- -----------------------------------------------------
      lv_last_item_um := gt_main_data(i).item_um;
--add start 2.0
      lv_prev_lot_ctl := TO_CHAR(ln_lot_ctl);
--add end 2.0
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    -- =====================================================
    -- ���ׂ̏o�͂��s���Ă��Ȃ����ɂ́u�f�[�^�͂���܂���v���b�Z�[�W���o��
    -- =====================================================
    IF ( lv_data_out = '0' ) THEN
      -- -----------------------------------------------------
      -- ���ɑq�ɖ��ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- �f�[�^�����b�Z�[�W�o��
      -- -----------------------------------------------------
      lv_no_data_msg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                 ,gc_xxcmn_10122 ) ;
      insert_xml_plsql_table(iox_xml_data, 'msg', lv_no_data_msg,
                                                  gc_tag_type_data, gc_tag_value_type_char);
    ELSE
      -- �ȉ��͖��ׂ̏o��
-- 08/05/09 Y.Yamamoto ADD v1.2 End
    -- -----------------------------------------------------
    -- �P�ʊJ�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �P�ʃf�[�^�^�O�o��
    -- -----------------------------------------------------
    -- �P��
    insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( lv_last_item_um, 1, 4 ),
                                                        gc_tag_type_data, gc_tag_value_type_char);
--add start 2.0
    -- -----------------------------------------------------
    -- ���b�g�Ǘ��敪�f�[�^�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lot_ctl', lv_prev_lot_ctl,
                                                        gc_tag_type_data, gc_tag_value_type_char);
--add end 2.0
    -- -----------------------------------------------------
    -- �P�ʏI���^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �敪���ׂf�I���^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    -- =====================================================
    -- ���ׂ̏o�͎��A�����܂�
    -- =====================================================
    END IF;
-- 08/05/09 Y.Yamamoto ADD v1.2 End
    -- -----------------------------------------------------
    -- ���ɑq�ɖ��ׂf�I���^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �q�ɂf�I���^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, '/lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �f�[�^�f�I���^�O
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, '/root', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_date_ym            IN     VARCHAR2         --   01 : �Ώ۔N��
     ,iv_whse_dept1         IN     VARCHAR2         --   02 : �q�ɊǗ�����1
     ,iv_whse_dept2         IN     VARCHAR2         --   03 : �q�ɊǗ�����2
     ,iv_whse_dept3         IN     VARCHAR2         --   04 : �q�ɊǗ�����3
     ,iv_whse_code1         IN     VARCHAR2         --   05 : �q�ɃR�[�h1
     ,iv_whse_code2         IN     VARCHAR2         --   06 : �q�ɃR�[�h2
     ,iv_whse_code3         IN     VARCHAR2         --   07 : �q�ɃR�[�h3
     ,iv_block_code1        IN     VARCHAR2         --   08 : �u���b�N1
     ,iv_block_code2        IN     VARCHAR2         --   09 : �u���b�N2
     ,iv_block_code3        IN     VARCHAR2         --   10 : �u���b�N3
     ,iv_item_class         IN     VARCHAR2         --   11 : ���i�敪
     ,iv_um_class           IN     VARCHAR2         --   12 : �P�ʋ敪
     ,iv_item_div           IN     VARCHAR2         --   13 : �i�ڋ敪
     ,iv_item_no1           IN     VARCHAR2         --   14 : �i�ڃR�[�h1
     ,iv_item_no2           IN     VARCHAR2         --   15 : �i�ڃR�[�h2
     ,iv_item_no3           IN     VARCHAR2         --   16 : �i�ڃR�[�h3
     ,iv_create_date1       IN     VARCHAR2         --   17 : �����N����1
     ,iv_create_date2       IN     VARCHAR2         --   18 : �����N����2
     ,iv_create_date3       IN     VARCHAR2         --   19 : �����N����3
     ,iv_lot_no1            IN     VARCHAR2         --   20 : ���b�gNo1
     ,iv_lot_no2            IN     VARCHAR2         --   21 : ���b�gNo2
     ,iv_lot_no3            IN     VARCHAR2         --   22 : ���b�gNo3
     ,iv_output_ctl         IN     VARCHAR2         --   23 : ���كf�[�^�敪
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf   VARCHAR2(5000) ;                      --   �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1) ;                         --   ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) ;                      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec     rec_param_data ;          -- �p�����[�^��n���p
--
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
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
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gd_exec_date                 := SYSDATE ;               -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.iv_date_ym      := iv_date_ym ;            -- �Ώ۔N��
    lr_param_rec.iv_whse_dept1   := iv_whse_dept1 ;         -- �q�ɊǗ�����1
    lr_param_rec.iv_whse_dept2   := iv_whse_dept2 ;         -- �q�ɊǗ�����2
    lr_param_rec.iv_whse_dept3   := iv_whse_dept3 ;         -- �q�ɊǗ�����3
    lr_param_rec.iv_whse_code1   := iv_whse_code1 ;         -- �q�ɃR�[�h1
    lr_param_rec.iv_whse_code2   := iv_whse_code2 ;         -- �q�ɃR�[�h2
    lr_param_rec.iv_whse_code3   := iv_whse_code3 ;         -- �q�ɃR�[�h3
    lr_param_rec.iv_block_code1  := iv_block_code1 ;        -- �u���b�N1
    lr_param_rec.iv_block_code2  := iv_block_code2 ;        -- �u���b�N2
    lr_param_rec.iv_block_code3  := iv_block_code3 ;        -- �u���b�N3
    lr_param_rec.iv_item_class   := iv_item_class ;         -- ���i�敪
    lr_param_rec.iv_um_class     := iv_um_class ;           -- �P�ʋ敪
    lr_param_rec.iv_item_div     := iv_item_div ;           -- �i�ڋ敪
    lr_param_rec.iv_item_no1     := iv_item_no1 ;           -- �i�ڃR�[�h1
    lr_param_rec.iv_item_no2     := iv_item_no2 ;           -- �i�ڃR�[�h2
    lr_param_rec.iv_item_no3     := iv_item_no3 ;           -- �i�ڃR�[�h3
-- UPDATE START 2008/5/20 YTabata --
    lr_param_rec.iv_create_date1                            -- �����N����1
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_create_date1 ),gc_char_d_format);
    lr_param_rec.iv_create_date2                            -- �����N����2
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_create_date2 ),gc_char_d_format);
    lr_param_rec.iv_create_date3                            -- �����N����3
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_create_date3 ),gc_char_d_format);
/**
    lr_param_rec.iv_create_date1 := iv_create_date1 ;       -- �����N����1
    lr_param_rec.iv_create_date2 := iv_create_date2 ;       -- �����N����2
    lr_param_rec.iv_create_date3 := iv_create_date3 ;       -- �����N����3
**/
-- UPDATE END 2008/5/20 YTabata --
    lr_param_rec.iv_lot_no1      := iv_lot_no1 ;            -- ���b�gNo1
    lr_param_rec.iv_lot_no2      := iv_lot_no2 ;            -- ���b�gNo2
    lr_param_rec.iv_lot_no3      := iv_lot_no3 ;            -- ���b�gNo3
    lr_param_rec.iv_output_ctl   := iv_output_ctl ;         -- ���كf�[�^�敪
    -- �ő���t�ݒ�
    gd_max_date                  := FND_DATE.STRING_TO_DATE( gc_max_date_d, gc_char_d_format );
--
    -- ====================================================
    -- �S�������擾
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--
    -- ====================================================
    -- �]�ƈ��敪�擾
    -- ====================================================
    SELECT papf.attribute3
    INTO   gv_employee_div
    FROM   fnd_user         fu
          ,per_all_people_f papf
    WHERE  fu.user_id     = FND_GLOBAL.USER_ID
    AND    papf.person_id = fu.employee_id
-- 08/05/20 add v1.5 start
-- 08/07/16 Y.Yamamoto Update v1.14 Start
--    AND    SYSDATE BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date,SYSDATE)
    AND    TRUNC( SYSDATE ) BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date,TRUNC( SYSDATE ))
-- 08/07/16 Y.Yamamoto Update v1.14 Start
-- 08/05 20 add v1.5 end
    ;
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N(A-1)
    -- =====================================================
    prc_check_param_info
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �I���X�i�b�v�V���b�g�쐬�v���O�����ďo(A-2)
    -- =====================================================
    prc_call_xxinv550004c
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��(A-3,4)
    -- =====================================================
    prc_create_xml_data
      (
        xml_data_table
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��(A-5)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_itemlocation_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_itemloc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_itemloc_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <msg>'        || lv_errmsg       || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_itemloc_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_itemloc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_itemlocation_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      --XML�f�[�^���o��
      <<xml_loop>>
      FOR i IN 1 .. xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_loop ;
--
    END IF ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_date_ym            IN     VARCHAR2         -- 01 : �Ώ۔N��
     ,iv_whse_dept1         IN     VARCHAR2         -- 02 : �q�ɊǗ�����1
     ,iv_whse_dept2         IN     VARCHAR2         -- 03 : �q�ɊǗ�����2
     ,iv_whse_dept3         IN     VARCHAR2         -- 04 : �q�ɊǗ�����3
     ,iv_whse_code1         IN     VARCHAR2         -- 05 : �q�ɃR�[�h1
     ,iv_whse_code2         IN     VARCHAR2         -- 06 : �q�ɃR�[�h2
     ,iv_whse_code3         IN     VARCHAR2         -- 07 : �q�ɃR�[�h3
     ,iv_block_code1        IN     VARCHAR2         -- 08 : �u���b�N1
     ,iv_block_code2        IN     VARCHAR2         -- 09 : �u���b�N2
     ,iv_block_code3        IN     VARCHAR2         -- 10 : �u���b�N3
     ,iv_item_class         IN     VARCHAR2         -- 11 : ���i�敪
     ,iv_um_class           IN     VARCHAR2         -- 12 : �P�ʋ敪
     ,iv_item_div           IN     VARCHAR2         -- 13 : �i�ڋ敪
     ,iv_item_no1           IN     VARCHAR2         -- 14 : �i�ڃR�[�h1
     ,iv_item_no2           IN     VARCHAR2         -- 15 : �i�ڃR�[�h2
     ,iv_item_no3           IN     VARCHAR2         -- 16 : �i�ڃR�[�h3
     ,iv_create_date1       IN     VARCHAR2         -- 17 : �����N����1
     ,iv_create_date2       IN     VARCHAR2         -- 18 : �����N����2
     ,iv_create_date3       IN     VARCHAR2         -- 19 : �����N����3
     ,iv_lot_no1            IN     VARCHAR2         -- 20 : ���b�gNo1
     ,iv_lot_no2            IN     VARCHAR2         -- 21 : ���b�gNo2
     ,iv_lot_no3            IN     VARCHAR2         -- 22 : ���b�gNo3
     ,iv_output_ctl         IN     VARCHAR2         -- 23 : ���كf�[�^�敪
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
    submain
      (
        iv_date_ym         => iv_date_ym          -- 01 : �Ώ۔N��
       ,iv_whse_dept1      => iv_whse_dept1       -- 02 : �q�ɊǗ�����1
       ,iv_whse_dept2      => iv_whse_dept2       -- 03 : �q�ɊǗ�����2
       ,iv_whse_dept3      => iv_whse_dept3       -- 04 : �q�ɊǗ�����3
       ,iv_whse_code1      => iv_whse_code1       -- 05 : �q�ɃR�[�h1
       ,iv_whse_code2      => iv_whse_code2       -- 06 : �q�ɃR�[�h2
       ,iv_whse_code3      => iv_whse_code3       -- 07 : �q�ɃR�[�h3
       ,iv_block_code1     => iv_block_code1      -- 08 : �u���b�N1
       ,iv_block_code2     => iv_block_code2      -- 09 : �u���b�N2
       ,iv_block_code3     => iv_block_code3      -- 10 : �u���b�N3
       ,iv_item_class      => iv_item_class       -- 11 : ���i�敪
       ,iv_um_class        => iv_um_class         -- 12 : �P�ʋ敪
       ,iv_item_div        => iv_item_div         -- 13 : �i�ڋ敪
       ,iv_item_no1        => iv_item_no1         -- 14 : �i�ڃR�[�h1
       ,iv_item_no2        => iv_item_no2         -- 15 : �i�ڃR�[�h2
       ,iv_item_no3        => iv_item_no3         -- 16 : �i�ڃR�[�h3
       ,iv_create_date1    => iv_create_date1     -- 17 : �����N����1
       ,iv_create_date2    => iv_create_date2     -- 18 : �����N����2
       ,iv_create_date3    => iv_create_date3     -- 19 : �����N����3
       ,iv_lot_no1         => iv_lot_no1          -- 20 : ���b�gNo1
       ,iv_lot_no2         => iv_lot_no2          -- 21 : ���b�gNo2
       ,iv_lot_no3         => iv_lot_no3          -- 22 : ���b�gNo3
       ,iv_output_ctl      => iv_output_ctl       -- 23 : ���كf�[�^�敪
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
END xxinv550001c ;
/
