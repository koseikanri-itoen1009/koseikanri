CREATE OR REPLACE PACKAGE BODY xxpo710001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo710001c(body)
 * Description      : ���Y�����i�d���j
 * MD.050/070       : ���Y�����i�d���jIssue1.0  (T_MD050_BPO_710)
 *                    �r�������\                (T_MD070_BPO_71B)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XML�f�[�^�ϊ�
 *  insert_xml_plsql_table    XML�f�[�^�i�[
 *  prc_initialize            �O����(B-2)
 *  prc_get_report_data       ���׃f�[�^�擾(B-3)
 *  prc_create_xml_data       �w�l�k�f�[�^�쐬(B-4)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2007/12/28    1.0   Yasuhisa Yamamoto  �V�K�쐬
 *  2008/05/02    1.1   Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(710_10)
 *  2008/05/19    1.2   Masayuki Ikeda     �����ύX�v��#62�Ή�
 *  2008/05/20    1.3   Yohei    Takayama  �����e�X�g��Q�Ή�(710_11)
 *  2008/07/02    1.4   Satoshi Yunba      �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
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
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxpo710001c' ;      -- �p�b�P�[�W��
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXPO710001T';       -- ���[ID
  gc_report_title_kari         CONSTANT VARCHAR2(20)  := '�i���j�r�������\' ; -- ���[�^�C�g���i���[��ʁF1�j
  gc_report_title              CONSTANT VARCHAR2(20)  := '�r�������\' ;       -- ���[�^�C�g���i���[��ʁF2�j
  gc_report_type_1             CONSTANT VARCHAR2(1)   := '1' ;                -- ���[��ʁi1�F���P���g�p�j
  gc_report_type_2             CONSTANT VARCHAR2(1)   := '2' ;                -- ���[��ʁi2�F���P���g�p�j
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;                -- �o�̓^�O�^�C�v�iT�F�^�O�j
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;                -- �o�̓^�O�^�C�v�iD�F�f�[�^�j
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;                -- �o�̓^�C�v�iC�FChar�j
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_final_unit_price_entered  CONSTANT VARCHAR2(1)   := 'Y' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;            -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po            CONSTANT VARCHAR2(5)   := 'XXPO' ;             -- �A�v���P�[�V�����iXXPO�j
  gc_xxpo_00036                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ;   -- �S�����������擾���b�Z�[�W
  gc_xxpo_00026                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ;   -- �S���Җ����擾���b�Z�[�W
  gc_xxpo_00033                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00033' ;   -- �f�[�^���擾���b�Z�[�W
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;  -- ����0���p���b�Z�[�W

  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
  gc_max_date_dt               CONSTANT VARCHAR2(19)  := '4712/12/31 23:59:59';
  gc_min_date_dt               CONSTANT VARCHAR2(19)  := '1900/01/01 00:00:00';
-- S 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ S --
  gc_max_date                  CONSTANT DATE  := FND_DATE.CANONICAL_TO_DATE( '4712/12/31' ) ;
  gc_min_date                  CONSTANT DATE  := FND_DATE.CANONICAL_TO_DATE( '1900/01/01' ) ;
-- E 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ E --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      iv_report_type      fnd_lookup_values.lookup_code%TYPE          --   01 : ���[���
     ,iv_creat_date_from  VARCHAR2(10)                                --   02 : ��������FROM
     ,iv_creat_date_to    VARCHAR2(10)                                --   03 : ��������TO
     ,iv_entry_num        xxpo_namaha_prod_txns.entry_number%TYPE     --   04 : �`�[NO
     ,iv_item_code        xxpo_namaha_prod_txns.aracha_item_code%TYPE --   05 : �d��i��
     ,iv_department_code  xxpo_namaha_prod_txns.department_code%TYPE  --   06 : ���͕���
     ,iv_employee_number  per_all_people_f.employee_number%TYPE       --   07 : ���͒S����
     ,iv_input_date_from  VARCHAR2(19)                                --   08 : ���͊���FROM
     ,iv_input_date_to    VARCHAR2(19)                                --   09 : ���͊���TO
    ) ;
--
  -- �r�������\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
     report_title           VARCHAR2(16)                                         -- ���[�^�C�g��
    ,entry_number           xxpo_namaha_prod_txns.entry_number%TYPE              -- �`�[No
    ,item_no                xxcmn_item_mst_v.item_no%TYPE                        -- �i�ځi�R�[�h�j
    ,item_short_name        xxcmn_item_mst_v.item_short_name%TYPE                -- �i�ځi���j
    ,lot_no                 ic_lots_mst.lot_no%TYPE                              -- ���b�gNo
    ,creation_date          ic_lots_mst.attribute1%TYPE                          -- ������
    ,location_code          xxpo_namaha_prod_txns.location_code%TYPE             -- ���ɐ�R�[�h
    ,description            xxpo_namaha_prod_txns.description%TYPE               -- ���l
    ,collect1_quantity      xxpo_namaha_prod_txns.collect1_quantity%TYPE         -- �W�ׂP�F����
    ,collect1_unit_price    xxpo_namaha_prod_txns.collect1_final_unit_price%TYPE -- �W�ׂP�F�P��
    ,collect2_quantity      xxpo_namaha_prod_txns.collect2_quantity%TYPE         -- �W�ׂQ�F����
    ,collect2_unit_price    xxpo_namaha_prod_txns.collect2_final_unit_price%TYPE -- �W�ׂQ�F�P��
    ,receive1_quantity      xxpo_namaha_prod_txns.receive1_quantity%TYPE         -- ����P�F����
    ,receive1_unit_price    xxpo_namaha_prod_txns.receive1_final_unit_price%TYPE -- ����P�F�P��
    ,receive2_quantity      xxpo_namaha_prod_txns.receive2_quantity%TYPE         -- ����Q�F����
    ,receive2_unit_price    xxpo_namaha_prod_txns.receive2_final_unit_price%TYPE -- ����Q�F�P��
    ,shipment_quantity      xxpo_namaha_prod_txns.shipment_quantity%TYPE         -- �o�ׁF����
    ,shipment_unit_price    xxpo_namaha_prod_txns.shipment_final_unit_price%TYPE -- �o�ׁF�P��
    ,byproduct1_item_code   xxcmn_item_mst_v.item_no%TYPE                        -- ���Y���P�F�i�ڃR�[�h
    ,byproduct1_item_name   xxcmn_item_mst_v.item_short_name%TYPE                -- ���Y���P�F�i�ږ�
    ,byproduct1_lot_num     xxpo_namaha_prod_txns.byproduct1_lot_number%TYPE     -- ���Y���P�F���b�gNo
    ,byproduct1_quantity    xxpo_namaha_prod_txns.byproduct1_quantity%TYPE       -- ���Y���P�F����
    ,byproduct1_unit_price  NUMBER                                               -- ���Y���P�F�P��
    ,byproduct2_item_code   xxcmn_item_mst_v.item_no%TYPE                        -- ���Y���Q�F�i�ڃR�[�h
    ,byproduct2_item_name   xxcmn_item_mst_v.item_short_name%TYPE                -- ���Y���Q�F�i�ږ�
    ,byproduct2_lot_num     xxpo_namaha_prod_txns.byproduct2_lot_number%TYPE     -- ���Y���Q�F���b�gNo
    ,byproduct2_quantity    xxpo_namaha_prod_txns.byproduct2_quantity%TYPE       -- ���Y���Q�F����
    ,byproduct2_unit_price  NUMBER                                               -- ���Y���Q�F�P��
    ,byproduct3_item_code   xxcmn_item_mst_v.item_no%TYPE                        -- ���Y���R�F�i�ڃR�[�h
    ,byproduct3_item_name   xxcmn_item_mst_v.item_short_name%TYPE                -- ���Y���R�F�i�ږ�
    ,byproduct3_lot_num     xxpo_namaha_prod_txns.byproduct3_lot_number%TYPE     -- ���Y���R�F���b�gNo
    ,byproduct3_quantity    xxpo_namaha_prod_txns.byproduct3_quantity%TYPE       -- ���Y���R�F����
    ,byproduct3_unit_price  NUMBER                                               -- ���Y���R�F�P��
    ,aracha_quantity        xxpo_namaha_prod_txns.aracha_quantity%TYPE           -- �r���������v�F����
    ,processing_unit_price  xxpo_namaha_prod_txns.processing_unit_price%TYPE     -- ���H�P��
    ,syanai_unit_price      NUMBER                                               -- �Г��P��
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gd_exec_date              DATE ;               -- ���{��
  gv_department_code        VARCHAR2(10) ;       -- �S������
  gv_department_name        VARCHAR2(14) ;       -- �S����
--
  gt_main_data              tab_data_type_dtl ;  -- �擾���R�[�h�\
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
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'99990.900');
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'9999990.90');
    ELSE
      iox_xml_data(i).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data(i).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(B-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize
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
    -- *** ���[�J���ϐ� ***
    ln_data_cnt     NUMBER := 0 ;   -- �f�[�^�����擾�p
    lv_err_code     VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    get_value_expt  EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S�������擾
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
-- 08/05/20 Y.Takayama DEL v1.3 Start
--    IF ( gv_department_code IS NULL ) THEN
--      lv_err_code := gc_xxpo_00036 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.3 End
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
-- 08/05/20 Y.Takayama DEL v1.3 Start
--    IF ( gv_department_name IS NULL ) THEN
--      lv_err_code := gc_xxpo_00026 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.3 End
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(B-3)
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
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_main_data
      (
        in_report_type      fnd_lookup_values.lookup_code%TYPE
       ,in_creat_date_from  VARCHAR2
       ,in_creat_date_to    VARCHAR2
       ,in_entry_num        xxpo_namaha_prod_txns.entry_number%TYPE
       ,in_item_code        xxpo_namaha_prod_txns.aracha_item_code%TYPE
       ,in_department_code  xxpo_namaha_prod_txns.department_code%TYPE
       ,in_employee_number  per_all_people_f.employee_number%TYPE
       ,in_input_date_from  VARCHAR2
       ,in_input_date_to    VARCHAR2
      )
    IS
      SELECT CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN gc_report_title_kari
              WHEN ( in_report_type = gc_report_type_2 ) THEN gc_report_title
             END                           report_title          -- ���[�^�C�g��
            ,xnpt.entry_number          AS entry_number          -- �`�[No
            ,ximv.item_no               AS item_no               -- �i�ځi�R�[�h�j
            ,ximv.item_short_name       AS item_short_name       -- �i�ځi���j
            ,ilm.lot_no                 AS lot_no                -- ���b�gNo
            ,ilm.attribute1             AS creation_date         -- ������
            ,xnpt.location_code         AS location_code         -- ���ɐ�R�[�h
            ,xnpt.description           AS description           -- ���l
            ,xnpt.collect1_quantity     AS collect1_quantity     -- �W�ׂP�F����
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.collect1_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.collect1_final_unit_price
             END                           collect1_unit_price   -- �W�ׂP�F�P��
            ,xnpt.collect2_quantity     AS collect2_quantity     -- �W�ׂQ�F����
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.collect2_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.collect2_final_unit_price
             END                           collect2_unit_price   -- �W�ׂQ�F�P��
            ,xnpt.receive1_quantity     AS receive1_quantity     -- ����P�F����
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.receive1_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.receive1_final_unit_price
             END                           receive1_unit_price   -- ����P�F�P��
            ,xnpt.receive2_quantity     AS receive2_quantity     -- ����Q�F����
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.receive2_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.receive2_final_unit_price
             END                           receive2_unit_price   -- ����Q�F�P��
            ,xnpt.shipment_quantity     AS shipment_quantity     -- �o�ׁF����
            ,CASE
              WHEN ( in_report_type = gc_report_type_1 ) THEN xnpt.shipment_temp_unit_price
              WHEN ( in_report_type = gc_report_type_2 ) THEN xnpt.shipment_final_unit_price
             END                           shipment_unit_price   -- �o�ׁF�P��
            ,ximv_by1.item_no           AS byproduct1_item_code  -- ���Y���P�F�i�ڃR�[�h
            ,ximv_by1.item_short_name   AS byproduct1_item_name  -- ���Y���P�F�i�ږ�
            ,xnpt.byproduct1_lot_number AS byproduct1_lot_num    -- ���Y���P�F���b�gNo
            ,xnpt.byproduct1_quantity   AS byproduct1_quantity   -- ���Y���P�F����
            ,ilm_by1.attribute7         AS byproduct1_unit_price -- ���Y���P�F�P��
            ,ximv_by2.item_no           AS byproduct2_item_code  -- ���Y���Q�F�i�ڃR�[�h
            ,ximv_by2.item_short_name   AS byproduct2_item_name  -- ���Y���Q�F�i�ږ�
            ,xnpt.byproduct2_lot_number AS byproduct2_lot_num    -- ���Y���Q�F���b�gNo
            ,xnpt.byproduct2_quantity   AS byproduct2_quantity   -- ���Y���Q�F����
            ,ilm_by2.attribute7         AS byproduct2_unit_price -- ���Y���Q�F�P��
            ,ximv_by3.item_no           AS byproduct3_item_code  -- ���Y���R�F�i�ڃR�[�h
            ,ximv_by3.item_short_name   AS byproduct3_item_name  -- ���Y���R�F�i�ږ�
            ,xnpt.byproduct3_lot_number AS byproduct3_lot_num    -- ���Y���R�F���b�gNo
            ,xnpt.byproduct3_quantity   AS byproduct3_quantity   -- ���Y���R�F����
            ,ilm_by3.attribute7         AS byproduct3_unit_price -- ���Y���R�F�P��
            ,xnpt.aracha_quantity       AS aracha_quantity       -- �r���������v�F����
            ,xnpt.processing_unit_price AS processing_unit_price -- ���H�P��
            ,TO_NUMBER( NVL( ilm.attribute7, '0' ) )
                                        AS syanai_unit_price     -- �Г��P��
      FROM   xxpo_namaha_prod_txns      xnpt                     -- ���t���сi�A�h�I���j
            ,ic_lots_mst                ilm                      -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v          ximv                     -- OPM�i�ڏ��VIEW2
            ,ic_lots_mst                ilm_by1                  -- OPM���b�g�}�X�^�i���Y���P�j
            ,xxcmn_item_mst2_v          ximv_by1                 -- OPM�i�ڏ��VIEW2�i���Y���P�j
            ,ic_lots_mst                ilm_by2                  -- OPM���b�g�}�X�^�i���Y���Q�j
            ,xxcmn_item_mst2_v          ximv_by2                 -- OPM�i�ڏ��VIEW2�i���Y���Q�j
            ,ic_lots_mst                ilm_by3                  -- OPM���b�g�}�X�^�i���Y���R�j
            ,xxcmn_item_mst2_v          ximv_by3                 -- OPM�i�ڏ��VIEW2�i���Y���R�j
            ,fnd_user                   fu                       -- ���[�U�}�X�^
            ,per_all_people_f           papf                     -- �]�ƈ��}�X�^
      ---------------------------------------------------------------------------------------------
      -- ��������
      WHERE xnpt.aracha_item_id     = ilm.item_id
      AND   xnpt.aracha_lot_id      = ilm.lot_id
      AND   xnpt.aracha_item_id     = ximv.item_id
-- S 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   ilm.attribute1          BETWEEN TO_CHAR( ximv.start_date_active , gc_char_d_format)
--                                    AND     NVL( TO_CHAR( ximv.end_date_active, gc_char_d_format), gc_max_date_d )
      AND   FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              BETWEEN ximv.start_date_active AND NVL( ximv.end_date_active, gc_max_date )
-- E 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ E --
      AND   xnpt.byproduct1_item_id = ilm_by1.item_id(+)
      AND   xnpt.byproduct1_lot_id  = ilm_by1.lot_id(+)
      AND   xnpt.byproduct1_item_id = ximv_by1.item_id(+)
      AND   (  ilm_by1.attribute1   IS NULL
            OR ilm_by1.attribute1   BETWEEN TO_CHAR( ximv_by1.start_date_active , gc_char_d_format)
                                    AND NVL( TO_CHAR( ximv_by1.end_date_active, gc_char_d_format), gc_max_date_d) )
      AND   xnpt.byproduct2_item_id = ilm_by2.item_id(+)
      AND   xnpt.byproduct2_lot_id  = ilm_by2.lot_id(+)
      AND   xnpt.byproduct2_item_id = ximv_by2.item_id(+)
      AND   (  ilm_by2.attribute1   IS NULL
            OR ilm_by2.attribute1   BETWEEN TO_CHAR( ximv_by2.start_date_active , gc_char_d_format)
                                    AND NVL( TO_CHAR( ximv_by2.end_date_active, gc_char_d_format), gc_max_date_d) )
      AND   xnpt.byproduct3_item_id = ilm_by3.item_id(+)
      AND   xnpt.byproduct3_lot_id  = ilm_by3.lot_id(+)
      AND   xnpt.byproduct3_item_id = ximv_by3.item_id(+)
      AND   (  ilm_by3.attribute1   IS NULL
            OR ilm_by3.attribute1   BETWEEN TO_CHAR( ximv_by3.start_date_active , gc_char_d_format)
                                    AND NVL( TO_CHAR( ximv_by3.end_date_active, gc_char_d_format), gc_max_date_d) )
      AND   xnpt.created_by         = fu.user_id
      AND   fu.employee_id          = papf.person_id
      ---------------------------------------------------------------------------------------------
      -- ���o����
      AND   (
              (   in_report_type                    = gc_report_type_2                -- ���[��ʁF2�̂Ƃ�
              AND xnpt.final_unit_price_entered_flg = gc_final_unit_price_entered )   -- ���P�����͊����t���O��'Y'
            OR
              ( in_report_type    = gc_report_type_1 )                                -- ���[��ʁF1�̂Ƃ�
            )
-- S 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   ilm.attribute1 BETWEEN NVL( in_creat_date_from, gc_min_date_d )  -- �p�����[�^�̐�������
--                           AND     NVL( in_creat_date_to  , gc_max_date_d )  -- �L���ȃf�[�^
      AND   FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              BETWEEN NVL( FND_DATE.CANONICAL_TO_DATE( in_creat_date_from ), gc_min_date )  -- �p�����[�^�̐�������
              AND     NVL( FND_DATE.CANONICAL_TO_DATE( in_creat_date_to   ), gc_max_date )  -- �L���ȃf�[�^
-- E 2008/05/16 1.2 MOD BY M.Ikeda ------------------------------------------------------------ E --
      AND   xnpt.aracha_quantity    > 0                               -- ����0�͎�������ꂽ�f�[�^�ׁ̈A���O
      AND   (  in_entry_num         IS NULL                           -- �`�[No���w��̓`�[No
            OR xnpt.entry_number    = in_entry_num )                  -- 
      AND   (  in_item_code         IS NULL                           -- �r���i�ڃR�[�h���w��̎d��i��
            OR xnpt.aracha_item_code = in_item_code )                 -- 
      AND   (  in_department_code   IS NULL                           -- �����R�[�h���w��̓��͕���
            OR xnpt.department_code = in_department_code )            -- 
      AND   (  in_employee_number   IS NULL                           -- �]�ƈ��ԍ����w��̓��͒S����
            OR papf.employee_number = in_employee_number )            -- 
      AND   xnpt.creation_date
              BETWEEN FND_DATE.CANONICAL_TO_DATE( in_input_date_from ) -- �p�����[�^�̓��͊��Ԃ�
              AND     NVL( FND_DATE.CANONICAL_TO_DATE( in_input_date_to ), gc_max_date ) -- �L���ȃf�[�^
      ORDER BY TO_NUMBER( xnpt.entry_number )    -- �`�[No
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
    -- �J�[�\���I�[�v��
    OPEN cur_main_data
      (
        ir_param.iv_report_type         -- ���[���
       ,ir_param.iv_creat_date_from     -- ��������FROM
       ,ir_param.iv_creat_date_to       -- ��������TO
       ,ir_param.iv_entry_num           -- �`�[NO
       ,ir_param.iv_item_code           -- �d��i��
       ,ir_param.iv_department_code     -- ���͕���
       ,ir_param.iv_employee_number     -- ���͒S����
       ,ir_param.iv_input_date_from     -- ���͊���FROM
       ,ir_param.iv_input_date_to       -- ���͊���TO
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
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
   * Description      : �w�l�k�f�[�^�쐬(B-4)
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
    -- ���z�v�Z�p
    ln_collect1_amount           NUMBER := 0 ;           -- �W�ׂP�F���z
    ln_collect2_amount           NUMBER := 0 ;           -- �W�ׂQ�F���z
    ln_receive1_amount           NUMBER := 0 ;           -- ����P�F���z
    ln_receive2_amount           NUMBER := 0 ;           -- ����Q�F���z
    ln_shipment_amount           NUMBER := 0 ;           -- �o�ׁF���z
    ln_total_quantity            NUMBER := 0 ;           -- ���t���v�F����
    ln_total_amount              NUMBER := 0 ;           -- ���t���v�F���z
    ln_byproduct1_amount         NUMBER := 0 ;           -- ���Y���P�F���z
    ln_byproduct2_amount         NUMBER := 0 ;           -- ���Y���Q�F���z
    ln_byproduct3_amount         NUMBER := 0 ;           -- ���Y���R�F���z
    ln_byproduct_total_quantity  NUMBER := 0 ;           -- ���Y�����v�F����
    ln_byproduct_total_amount    NUMBER := 0 ;           -- ���Y�����v�F���z
    ln_aracha_unit_price         NUMBER := 0 ;           -- �r���������v�F�P��
    ln_aracha_amount             NUMBER := 0 ;           -- �r���������v�F���z
    ln_budomari                  NUMBER := 0 ;           -- ����
    ln_amount                    NUMBER := 0 ;           -- �Г��U�ցi�r���j�F���z
    ln_receive_total_quantity    NUMBER := 0 ;           -- ������v�F����
    ln_receive_total_amount      NUMBER := 0 ;           -- ������v�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
    ln_syanai_unit_price         NUMBER := 0 ;           -- �Г��P��
-- 08/05/02 Y.Yamamoto ADD v1.1 End
--
    -- ���ɑq�Ɏ擾�p
    lv_location_name             xxcmn_item_locations_v.description%TYPE ; -- ���ɑq��
--
    -- *** ���[�J���E��O���� ***
    no_data_expt                 EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
  BEGIN
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
    -- -----------------------------------------------------
    -- �f�[�^�f�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'root',      NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �`�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lg_entry_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- -----------------------------------------------------
      -- ���ɑq�ɂ̎擾
      -- -----------------------------------------------------
      BEGIN
        SELECT SUBSTRB( xilv.description, 1, 20 )
        INTO   lv_location_name
        FROM   xxcmn_item_locations2_v xilv
        WHERE  xilv.segment1 = gt_main_data(i).location_code
        AND    gt_main_data(i).creation_date BETWEEN TO_CHAR( xilv.date_from , gc_char_d_format)
                                             AND     NVL( TO_CHAR( xilv.date_to, gc_char_d_format), gc_max_date_d)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_location_name := NULL ;
      END ;
      -- -----------------------------------------------------
      -- �v�Z���ڂ̎Z�o
      -- -----------------------------------------------------
      -- �ʌv�Z����
-- 08/05/02 Y.Yamamoto Update v1.1 Start �v�Z�Ɏg�p����e���ڂɂ��āANVL��������悤�ɏC������B
      ln_collect1_amount          := ROUND( NVL( gt_main_data(i).collect1_quantity, 0 ) 
                                            * NVL( gt_main_data(i).collect1_unit_price, 0 ) ) ;
      ln_collect2_amount          := ROUND( NVL( gt_main_data(i).collect2_quantity, 0 ) 
                                            * NVL( gt_main_data(i).collect2_unit_price, 0 ) ) ;
      ln_receive1_amount          := ROUND( NVL( gt_main_data(i).receive1_quantity, 0 ) 
                                            * NVL( gt_main_data(i).receive1_unit_price, 0 ) ) ;
      ln_receive2_amount          := ROUND( NVL( gt_main_data(i).receive2_quantity, 0 ) 
                                            * NVL( gt_main_data(i).receive2_unit_price, 0 ) ) ;
      ln_shipment_amount          := ROUND( NVL( gt_main_data(i).shipment_quantity, 0 ) 
                                            * NVL( gt_main_data(i).shipment_unit_price, 0 ) ) ;
--
      ln_total_quantity           := ( NVL( gt_main_data(i).collect1_quantity, 0 ) 
                                       + NVL( gt_main_data(i).collect2_quantity, 0 ) ) 
                                    + ( NVL( gt_main_data(i).receive1_quantity, 0 ) 
                                        + NVL( gt_main_data(i).receive2_quantity, 0 ) ) 
                                    -   NVL( gt_main_data(i).shipment_quantity, 0 ) ;
--
      ln_total_amount             := ( ln_collect1_amount + ln_collect2_amount ) 
                                     + ( ln_receive1_amount + ln_receive2_amount ) 
                                     -   ln_shipment_amount ;
--
      ln_byproduct1_amount        := ROUND( NVL( gt_main_data(i).byproduct1_quantity, 0 ) 
                                            * NVL( gt_main_data(i).byproduct1_unit_price, 0 ) ) ;
      ln_byproduct2_amount        := ROUND( NVL( gt_main_data(i).byproduct2_quantity, 0 ) 
                                            * NVL( gt_main_data(i).byproduct2_unit_price, 0 ) ) ;
      ln_byproduct3_amount        := ROUND( NVL( gt_main_data(i).byproduct3_quantity, 0 ) 
                                            * NVL( gt_main_data(i).byproduct3_unit_price, 0 ) ) ;
--
      ln_byproduct_total_quantity := NVL( gt_main_data(i).byproduct1_quantity, 0 ) 
                                     + NVL( gt_main_data(i).byproduct2_quantity, 0 ) 
                                     + NVL( gt_main_data(i).byproduct3_quantity, 0 ) ;
      ln_byproduct_total_amount   := ln_byproduct1_amount + ln_byproduct2_amount + ln_byproduct3_amount ;
--
      ln_aracha_amount            := ln_total_amount - ln_byproduct_total_amount ;
      ln_aracha_unit_price        := ROUND( ln_aracha_amount  / NVL( gt_main_data(i).aracha_quantity, 0 ), 2 ) ;
      ln_budomari                 := ROUND( ln_total_quantity / NVL( gt_main_data(i).aracha_quantity, 0 ), 2 ) ;
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      ln_syanai_unit_price        := ln_aracha_unit_price + NVL( gt_main_data(i).processing_unit_price, 0 ) ;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
-- 08/05/02 Y.Yamamoto Update v1.1 Start
--      ln_amount                   := ROUND( gt_main_data(i).aracha_quantity
--                                            * ( gt_main_data(i).processing_unit_price + ln_aracha_unit_price ) ) ;
      ln_amount                   := ROUND( NVL( gt_main_data(i).aracha_quantity, 0 ) * ln_syanai_unit_price ) ;
-- 08/05/02 Y.Yamamoto Update v1.1 End
      ln_receive_total_quantity   := NVL( gt_main_data(i).aracha_quantity, 0 ) + ln_byproduct_total_quantity ;
      ln_receive_total_amount     := ln_amount + ln_byproduct_total_amount ;
--
-- 08/05/02 Y.Yamamoto Update v1.1 End
      -- -----------------------------------------------------
      -- ���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_entry', NULL, gc_tag_type_tag, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���[�^�C�g��
      insert_xml_plsql_table(iox_xml_data, 'report_title', gt_main_data(i).report_title, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���[�h�c
      insert_xml_plsql_table(iox_xml_data, 'report_id', gc_report_id, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �`�[No
      insert_xml_plsql_table(iox_xml_data, 'entry_num', gt_main_data(i).entry_number, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���{��
      insert_xml_plsql_table(iox_xml_data, 'exec_date', TO_CHAR( gd_exec_date, gc_char_dt_format ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �i�ځi�R�[�h�j
      insert_xml_plsql_table(iox_xml_data, 'item_code', SUBSTRB( TO_CHAR( gt_main_data(i).item_no ), 1, 7 ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �i�ځi���j
      insert_xml_plsql_table(iox_xml_data, 'item_name', gt_main_data(i).item_short_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���b�gNo
      insert_xml_plsql_table(iox_xml_data, 'lot_num', SUBSTRB( gt_main_data(i).lot_no, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �S������
      insert_xml_plsql_table(iox_xml_data, 'department_code', gv_department_code, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �S����
      insert_xml_plsql_table(iox_xml_data, 'department_name', gv_department_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ������
      insert_xml_plsql_table(iox_xml_data, 'creation_date', SUBSTRB( gt_main_data(i).creation_date, 1, 10 ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���ɑq��
      insert_xml_plsql_table(iox_xml_data, 'location_name', lv_location_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���l
      insert_xml_plsql_table(iox_xml_data, 'description', SUBSTRB( gt_main_data(i).description, 1, 50 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      ------------------------------
      -- ���ׂk�f�J�n�^�O
      ------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_entry_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
      -- -----------------------------------------------------
      -- ���ׂk�f�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- �W�ׂP�F����
      insert_xml_plsql_table(iox_xml_data, 'collect1_quantity', TO_CHAR( gt_main_data(i).collect1_quantity ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �W�ׂP�F�P��
      insert_xml_plsql_table(iox_xml_data, 'collect1_unit_price', TO_CHAR( gt_main_data(i).collect1_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �W�ׂP�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_collect1_amount = 0 ) THEN
        ln_collect1_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'collect1_amount', TO_CHAR( ln_collect1_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �W�ׂQ�F����
      insert_xml_plsql_table(iox_xml_data, 'collect2_quantity', TO_CHAR( gt_main_data(i).collect2_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �W�ׂQ�F�P��
      insert_xml_plsql_table(iox_xml_data, 'collect2_unit_price', TO_CHAR( gt_main_data(i).collect2_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �W�ׂQ�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_collect2_amount = 0 ) THEN
        ln_collect2_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'collect2_amount', TO_CHAR( ln_collect2_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ����P�F����
      insert_xml_plsql_table(iox_xml_data, 'receive1_quantity', TO_CHAR( gt_main_data(i).receive1_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ����P�F�P��
      insert_xml_plsql_table(iox_xml_data, 'receive1_unit_price', TO_CHAR( gt_main_data(i).receive1_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ����P�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive1_amount = 0 ) THEN
        ln_receive1_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive1_amount', TO_CHAR( ln_receive1_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ����Q�F����
      insert_xml_plsql_table(iox_xml_data, 'receive2_quantity', TO_CHAR( gt_main_data(i).receive2_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ����Q�F�P��
      insert_xml_plsql_table(iox_xml_data, 'receive2_unit_price', TO_CHAR( gt_main_data(i).receive2_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ����Q�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive2_amount = 0 ) THEN
        ln_receive2_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive2_amount', TO_CHAR( ln_receive2_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �o�ׁF����
      insert_xml_plsql_table(iox_xml_data, 'shipment_quantity', TO_CHAR( gt_main_data(i).shipment_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �o�ׁF�P��
      insert_xml_plsql_table(iox_xml_data, 'shipment_unit_price', TO_CHAR( gt_main_data(i).shipment_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �o�ׁF���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_shipment_amount = 0 ) THEN
        ln_shipment_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'shipment_amount', TO_CHAR( ln_shipment_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ���t���v�F����
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_total_quantity = 0 ) THEN
        ln_total_quantity := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'total_quantity', TO_CHAR( ln_total_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���t���v�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_total_amount = 0 ) THEN
        ln_total_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'total_amount', TO_CHAR( ln_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ���Y���P�F�i�ځi�R�[�h�j
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_item_code', 
                                                          SUBSTRB( gt_main_data(i).byproduct1_item_code, 1, 7 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���P�F�i�ځi���j
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_item_name', gt_main_data(i).byproduct1_item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���P�F���b�gNo
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_lot_num', 
                                                          SUBSTRB( gt_main_data(i).byproduct1_lot_num, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���P�F����
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_quantity', TO_CHAR( gt_main_data(i).byproduct1_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���P�F�P��
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_unit_price', 
                                                          TO_CHAR( gt_main_data(i).byproduct1_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���P�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct1_amount = 0 ) THEN
        ln_byproduct1_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct1_amount', TO_CHAR( ln_byproduct1_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ���Y���Q�F�i�ځi�R�[�h�j
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_item_code', 
                                                          SUBSTRB( gt_main_data(i).byproduct2_item_code, 1, 7 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���Q�F�i�ځi���j
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_item_name', gt_main_data(i).byproduct2_item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���Q�F���b�gNo
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_lot_num', 
                                                          SUBSTRB( gt_main_data(i).byproduct2_lot_num, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���Q�F����
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_quantity', TO_CHAR( gt_main_data(i).byproduct2_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���Q�F�P��
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_unit_price', 
                                                          TO_CHAR( gt_main_data(i).byproduct2_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���Q�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct2_amount = 0 ) THEN
        ln_byproduct2_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct2_amount', TO_CHAR( ln_byproduct2_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ���Y���R�F�i�ځi�R�[�h�j
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_item_code', 
                                                          SUBSTRB( gt_main_data(i).byproduct3_item_code, 1, 7 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���R�F�i�ځi���j
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_item_name', gt_main_data(i).byproduct3_item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���R�F���b�gNo
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_lot_num', 
                                                          SUBSTRB( gt_main_data(i).byproduct3_lot_num, 1, 10 ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���R�F����
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_quantity', TO_CHAR( gt_main_data(i).byproduct3_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���R�F�P��
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_unit_price', 
                                                          TO_CHAR( gt_main_data(i).byproduct3_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y���R�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct3_amount = 0 ) THEN
        ln_byproduct3_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct3_amount', TO_CHAR( ln_byproduct3_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ���Y�����v�F����
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct_total_quantity = 0 ) THEN
        ln_byproduct_total_quantity := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct_total_quantity', TO_CHAR( ln_byproduct_total_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���Y�����v�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_byproduct_total_amount = 0 ) THEN
        ln_byproduct_total_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'byproduct_total_amount', TO_CHAR( ln_byproduct_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �r���������v�F����
      insert_xml_plsql_table(iox_xml_data, 'aracha_quantity', TO_CHAR( gt_main_data(i).aracha_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �r���������v�F�P��
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_aracha_unit_price = 0 ) THEN
        ln_aracha_unit_price := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'aracha_unit_price', TO_CHAR( ln_aracha_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �r���������v�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_aracha_amount = 0 ) THEN
        ln_aracha_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'aracha_amount', TO_CHAR( ln_aracha_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ����
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_budomari = 0 ) THEN
        ln_budomari := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'budomari', TO_CHAR( ln_budomari ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      ------------------------------
      -- ���ׂk�f�I���^�O
      ------------------------------
      insert_xml_plsql_table(iox_xml_data, '/g_entry_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
      -- �Г��U�֋��z�i�r���j�F���H�P��
      insert_xml_plsql_table(iox_xml_data, 'processing_unit_price', 
                                                          TO_CHAR( gt_main_data(i).processing_unit_price ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
-- 08/05/02 Y.Yamamoto Update v1.1 Start
      -- �Г��U�֋��z�i�r���j�F�Г��P��
--      insert_xml_plsql_table(iox_xml_data, 'syanai_unit_price', TO_CHAR( gt_main_data(i).syanai_unit_price ), 
--                                                          gc_tag_type_data, gc_tag_value_type_char);
      IF ( ln_syanai_unit_price = 0 ) THEN
        ln_syanai_unit_price := NULL;
      END IF;
      insert_xml_plsql_table(iox_xml_data, 'syanai_unit_price', TO_CHAR( ln_syanai_unit_price ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
-- 08/05/02 Y.Yamamoto Update v1.1 End
      -- �Г��U�֋��z�i�r���j�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_amount = 0 ) THEN
        ln_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'amount', TO_CHAR( ln_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ������v�F����
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive_total_quantity = 0 ) THEN
        ln_receive_total_quantity := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive_total_quantity', TO_CHAR( ln_receive_total_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ������v�F���z
-- 08/05/02 Y.Yamamoto ADD v1.1 Start
      IF ( ln_receive_total_amount = 0 ) THEN
        ln_receive_total_amount := NULL;
      END IF;
-- 08/05/02 Y.Yamamoto ADD v1.1 End
      insert_xml_plsql_table(iox_xml_data, 'receive_total_amount', TO_CHAR( ln_receive_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- ���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, '/g_entry', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �`�[�f�I���^�O
    ------------------------------
    insert_xml_plsql_table(iox_xml_data, '/lg_entry_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    ------------------------------
    -- �f�[�^�f�I���^�O
    ------------------------------
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
      iv_report_type        IN     VARCHAR2         --   01 : ���[���
     ,iv_creat_date_from    IN     VARCHAR2         --   02 : ��������FROM
     ,iv_creat_date_to      IN     VARCHAR2         --   03 : ��������TO
     ,iv_entry_num          IN     VARCHAR2         --   04 : �`�[NO
     ,iv_item_code          IN     VARCHAR2         --   05 : �d��i��
     ,iv_department_code    IN     VARCHAR2         --   06 : ���͕���
     ,iv_employee_number    IN     VARCHAR2         --   07 : ���͒S����
     ,iv_input_date_from    IN     VARCHAR2         --   08 : ���͊���FROM
     ,iv_input_date_to      IN     VARCHAR2         --   09 : ���͊���TO
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
    gd_exec_date                    := SYSDATE ;               -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.iv_report_type     := iv_report_type ;        -- ���[���
    lr_param_rec.iv_creat_date_from := iv_creat_date_from ;    -- ��������FROM
    lr_param_rec.iv_creat_date_to   := iv_creat_date_to ;      -- ��������TO
    lr_param_rec.iv_entry_num       := iv_entry_num ;          -- �`�[NO
    lr_param_rec.iv_item_code       := iv_item_code ;          -- �d��i��
    lr_param_rec.iv_department_code := iv_department_code ;    -- ���͕���
    lr_param_rec.iv_employee_number := iv_employee_number ;    -- ���͒S����
    lr_param_rec.iv_input_date_from := iv_input_date_from ;    -- ���͊���FROM
    lr_param_rec.iv_input_date_to   := iv_input_date_to ;      -- ���͊���TO
--
    -- =====================================================
    -- �O����(B-2)
    -- =====================================================
    prc_initialize
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
    -- ���[�f�[�^�o��(B-3,4)
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
    -- �w�l�k�o��(B-4)
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_entry_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_entry>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <report_title>' || gc_report_title || '</report_title>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>'          || lv_errmsg       || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_entry>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_entry_info>' ) ;
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
     ,iv_report_type        IN     VARCHAR2         -- 01 : ���[���
     ,iv_creat_date_from    IN     VARCHAR2         -- 02 : ��������FROM
     ,iv_creat_date_to      IN     VARCHAR2         -- 03 : ��������TO
     ,iv_entry_num          IN     VARCHAR2         -- 04 : �`�[NO
     ,iv_item_code          IN     VARCHAR2         -- 05 : �d��i��
     ,iv_department_code    IN     VARCHAR2         -- 06 : ���͕���
     ,iv_employee_number    IN     VARCHAR2         -- 07 : ���͒S����
     ,iv_input_date_from    IN     VARCHAR2         -- 08 : ���͊���FROM
     ,iv_input_date_to      IN     VARCHAR2         -- 09 : ���͊���TO
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
        iv_report_type     => iv_report_type      -- 01 : ���[���
       ,iv_creat_date_from => iv_creat_date_from  -- 02 : ��������FROM
       ,iv_creat_date_to   => iv_creat_date_to    -- 03 : ��������TO
       ,iv_entry_num       => iv_entry_num        -- 04 : �`�[NO
       ,iv_item_code       => iv_item_code        -- 05 : �d��i��
       ,iv_department_code => iv_department_code  -- 06 : ���͕���
       ,iv_employee_number => iv_employee_number  -- 07 : ���͒S����
       ,iv_input_date_from => iv_input_date_from  -- 08 : ���͊���FROM
       ,iv_input_date_to   => iv_input_date_to    -- 09 : ���͊���TO
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
END xxpo710001c ;
/