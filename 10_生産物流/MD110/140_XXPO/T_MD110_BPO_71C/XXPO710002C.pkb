CREATE OR REPLACE PACKAGE BODY xxpo710002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo710002c(body)
 * Description      : ���Y�����i�d���j
 * MD.050/070       : ���Y�����i�d���jIssue1.0  (T_MD050_BPO_710)
 *                    �r�������\�݌v            (T_MD070_BPO_71C)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XML�f�[�^�ϊ�
 *  insert_xml_plsql_table    XML�f�[�^�i�[
 *  prc_initialize            �O����(C-2)
 *  prc_get_report_data       ���׃f�[�^�擾(C-3)
 *  prc_create_xml_data       �w�l�k�f�[�^�쐬(C-4)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/01/22    1.0   Yasuhisa Yamamoto  �V�K�쐬
 *  2008/05/20    1.1   Yohei    Takayama  �����e�X�g�Ή�(710_11)
 *  2008/07/02    1.2   Satoshi Yunba      �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
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
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxpo710002c' ;          -- �p�b�P�[�W��
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXPO710002T';           -- ���[ID
  gc_report_title_kari         CONSTANT VARCHAR2(20)  := '�i���j�r�������\�݌v' ; -- ���[�^�C�g���i���[��ʁF3�j
  gc_report_title              CONSTANT VARCHAR2(14)  := '�r�������\�݌v' ;       -- ���[�^�C�g���i���[��ʁF4�j
  gc_report_type_3             CONSTANT VARCHAR2(1)   := '3' ;                    -- ���[��ʁi3�F���P���g�p�j
  gc_report_type_4             CONSTANT VARCHAR2(1)   := '4' ;                    -- ���[��ʁi4�F���P���g�p�j
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;                    -- �o�̓^�O�^�C�v�iT�F�^�O�j
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;                    -- �o�̓^�O�^�C�v�iD�F�f�[�^�j
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;                    -- �o�̓^�C�v�iC�FChar�j
  gc_item_class_siage          CONSTANT VARCHAR2(4)   := '�d��' ;                 -- �敪�i�d��j
  gc_item_class_fuku           CONSTANT VARCHAR2(6)   := '���Y��' ;               -- �敪�i���Y���j
  gc_bypro_default_num         CONSTANT NUMBER        := 0 ;                      -- ���Y�����\���f�[�^�����l
  gc_out_year                  CONSTANT VARCHAR2(2)   := '�N' ;                   -- ���ԏo�͗p�i�N�j
  gc_out_month                 CONSTANT VARCHAR2(2)   := '��' ;                   -- ���ԏo�͗p�i���j
  gc_out_day                   CONSTANT VARCHAR2(2)   := '��' ;                   -- ���ԏo�͗p�i���j
  gc_out_part                  CONSTANT VARCHAR2(2)   := '�]' ;                   -- ���ԏo�͗p�i�]�j
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_final_unit_price_entered  CONSTANT VARCHAR2(1)   := 'Y' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;                -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po            CONSTANT VARCHAR2(5)   := 'XXPO' ;                 -- �A�v���P�[�V�����iXXPO�j
  gc_xxpo_00036                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ;       -- �S�����������擾���b�Z�[�W
  gc_xxpo_00026                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ;       -- �S���Җ����擾���b�Z�[�W
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;      -- ����0���p���b�Z�[�W
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
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
      iv_report_type           fnd_lookup_values.lookup_code%TYPE                 --   01 : ���[���
     ,iv_creat_date_from       VARCHAR2(10)                                       --   02 : ��������FROM
     ,iv_creat_date_to         VARCHAR2(10)                                       --   03 : ��������TO
    ) ;
--
  -- �r�������\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
     location_code             mtl_item_locations.segment1%TYPE                   -- ���ɑq�ɃR�[�h
    ,location_name             mtl_item_locations.description%TYPE                -- ���ɑq�ɖ�
    ,item_class                VARCHAR2(6)                                        -- �敪
    ,item_code                 xxpo_namaha_prod_txns.aracha_item_code%TYPE        -- �i���i�R�[�h�j
    ,item_name                 xxcmn_item_mst_b.item_short_name%TYPE              -- �i���i���j
    ,quantity                  xxpo_namaha_prod_txns.aracha_quantity%TYPE         -- ����
    ,stock_amount              NUMBER                                             -- �݌ɋ��z
    ,aracha_amount             NUMBER                                             -- �������z
    ,collect_quantity          xxpo_namaha_prod_txns.collect1_quantity%TYPE       -- �W�א���
    ,collect_amount            NUMBER                                             -- �W�׋��z
    ,receive_quantity          xxpo_namaha_prod_txns.receive1_quantity%TYPE       -- �������
    ,receive_amount            NUMBER                                             -- ������z
    ,shipment_quantity         xxpo_namaha_prod_txns.shipment_quantity%TYPE       -- �o�א���
    ,shipment_amount           NUMBER                                             -- �o�׋��z
    ,nahama_total_quantity     xxpo_namaha_prod_txns.aracha_quantity%TYPE         -- ���t���v����
    ,namaha_total_amount       NUMBER                                             -- ���t���v���z
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
  gv_department_code           VARCHAR2(10) ;                                     -- �S������
  gv_department_name           VARCHAR2(14) ;                                     -- �S����
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
   * Description      : �O����(C-2)
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
-- 08/05/20 Y.Takayama DEL v1.1 Start
--    IF ( gv_department_code IS NULL ) THEN
--      lv_err_code := gc_xxpo_00036 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.1 End
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
-- 08/05/20 Y.Takayama DEL v1.1 Start
--    IF ( gv_department_name IS NULL ) THEN
--      lv_err_code := gc_xxpo_00026 ;
--      RAISE get_value_expt ;
--    END IF ;
-- 08/05/20 Y.Takayama DEL v1.1 End
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
   * Description      : ���׃f�[�^�擾(C-3)
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
      )
    IS
      SELECT cmd.location_code                                                      -- ���ɐ�
            ,cmd.location_name                                                      -- ���ɐ於
            ,cmd.item_class                                                         -- �敪
            ,cmd.item_code                                                          -- �i��
            ,cmd.item_name                                                          -- �i��
            ,cmd.quantity                                                           -- ����
            ,cmd.stock_amount                                                       -- �݌ɋ��z
            ,cmd.aracha_amount                                                      -- �������z
            ,cmd.collect_quantity                                                   -- �W�א���
            ,cmd.collect_amount                                                     -- �W�׋��z
            ,cmd.receive_quantity                                                   -- �������
            ,cmd.receive_amount                                                     -- ������z
            ,cmd.shipment_quantity                                                  -- �o�א���
            ,cmd.shipment_amount                                                    -- �o�׋��z
            ,cmd.nahama_total_quantity                                              -- ���t���v����
            ,cmd.namaha_total_amount                                                -- ���t���v���z
      FROM
        (
          -- *** �d��i�ڏ��̃f�[�^�擾 ***
          SELECT xilv.segment1                            AS location_code          -- ���ɐ�
                ,xilv.description                         AS location_name          -- ���ɐ於
                ,gc_item_class_siage                      AS item_class             -- �敪�i�d��j�Œ�
                ,xnpt.aracha_item_code                    AS item_code              -- �i��
                ,ximv.item_short_name                     AS item_name              -- �i��
                ,SUM( NVL( xnpt.aracha_quantity, 0 ) )    AS quantity               -- ����
                ,SUM( ROUND( NVL( xnpt.aracha_quantity, 0 ) * TO_NUMBER( NVL( ilm.attribute7, '0') ) ) )
                                                          AS stock_amount           -- �݌ɋ��z
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.collect1_temp_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_temp_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_temp_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_temp_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_temp_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                   - SUM(  ROUND( NVL( xnpt.byproduct1_quantity, 0) * TO_NUMBER( NVL( ilm_by1.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct2_quantity, 0) * TO_NUMBER( NVL( ilm_by2.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct3_quantity, 0) * TO_NUMBER( NVL( ilm_by3.attribute7, '0') ) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.collect1_final_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_final_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_final_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_final_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_final_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                   - SUM(  ROUND( NVL( xnpt.byproduct1_quantity, 0) * TO_NUMBER( NVL( ilm_by1.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct2_quantity, 0) * TO_NUMBER( NVL( ilm_by2.attribute7, '0') ) )
                         + ROUND( NVL( xnpt.byproduct3_quantity, 0) * TO_NUMBER( NVL( ilm_by3.attribute7, '0') ) ) )
                 END                                         aracha_amount          -- �������z
                ,SUM( NVL( xnpt.collect1_quantity, 0) + NVL( xnpt.collect2_quantity, 0) )
                                                          AS collect_quantity       -- �W�א���
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.collect1_temp_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_temp_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.collect1_final_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_final_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) ) )
                 END                                         collect_amount         -- �W�׋��z
                ,SUM( NVL( xnpt.receive1_quantity, 0) + NVL( xnpt.receive2_quantity, 0) )
                                                          AS receive_quantity       -- �������
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.receive1_temp_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_temp_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.receive1_final_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_final_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) ) )
                 END                                         receive_amount         -- ������z
                ,SUM( NVL( xnpt.shipment_quantity, 0) )   AS shipment_quantity      -- �o�א���
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- ���P���ŎZ�o
                     SUM( ROUND( NVL( xnpt.shipment_temp_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- ���P���ŎZ�o
                     SUM( ROUND( NVL( xnpt.shipment_final_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                 END                                         shipment_amount        -- �o�׋��z
                ,SUM(  NVL( xnpt.collect1_quantity, 0) + NVL( xnpt.collect2_quantity, 0)
                     + NVL( xnpt.receive1_quantity, 0) + NVL( xnpt.receive2_quantity, 0)
                     - NVL( xnpt.shipment_quantity, 0) )  AS nahama_total_quantity  -- ���t���v����
                ,CASE
                  WHEN ( in_report_type = gc_report_type_3 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.collect1_temp_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_temp_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_temp_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_temp_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_temp_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                  WHEN ( in_report_type = gc_report_type_4 ) THEN                   -- ���P���ŎZ�o
                     SUM(  ROUND( NVL( xnpt.collect1_final_unit_price, 0) * NVL( xnpt.collect1_quantity, 0) )
                         + ROUND( NVL( xnpt.collect2_final_unit_price, 0) * NVL( xnpt.collect2_quantity, 0) )
                         + ROUND( NVL( xnpt.receive1_final_unit_price, 0) * NVL( xnpt.receive1_quantity, 0) )
                         + ROUND( NVL( xnpt.receive2_final_unit_price, 0) * NVL( xnpt.receive2_quantity, 0) )
                         - ROUND( NVL( xnpt.shipment_final_unit_price, 0) * NVL( xnpt.shipment_quantity, 0) ) )
                 END                                         namaha_total_amount    -- ���t���v���z
          FROM   xxpo_namaha_prod_txns    xnpt                                      -- ���t���сi�A�h�I���j
                ,ic_lots_mst              ilm                                       -- OPM���b�g�}�X�^
                ,xxcmn_item_mst2_v        ximv                                      -- OPM�i�ڏ��VIEW2
                ,ic_lots_mst              ilm_by1                                   -- OPM���b�g�}�X�^�i���Y���P�j
                ,ic_lots_mst              ilm_by2                                   -- OPM���b�g�}�X�^�i���Y���Q�j
                ,ic_lots_mst              ilm_by3                                   -- OPM���b�g�}�X�^�i���Y���R�j
                ,xxcmn_item_locations2_v  xilv                                      -- OPM�ۊǏꏊ���VIEW2
          ---------------------------------------------------------------------------------------------
          -- ��������
          WHERE xnpt.aracha_item_id     = ilm.item_id
          AND   xnpt.aracha_lot_id      = ilm.lot_id
          AND   xnpt.aracha_item_id     = ximv.item_id
          AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                   AND NVL( ximv.end_date_active, gd_max_date )
          AND   xnpt.byproduct1_item_id = ilm_by1.item_id(+)
          AND   xnpt.byproduct1_lot_id  = ilm_by1.lot_id(+)
          AND   xnpt.byproduct2_item_id = ilm_by2.item_id(+)
          AND   xnpt.byproduct2_lot_id  = ilm_by2.lot_id(+)
          AND   xnpt.byproduct3_item_id = ilm_by3.item_id(+)
          AND   xnpt.byproduct3_lot_id  = ilm_by3.lot_id(+)
          AND   xnpt.location_id        = xilv.inventory_location_id
          AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                   AND NVL( xilv.date_to, gd_max_date )
          ---------------------------------------------------------------------------------------------
          -- ���o����
          AND   ((    in_report_type    = gc_report_type_4                          -- ���[��ʁF4�̂Ƃ�
                  AND xnpt.final_unit_price_entered_flg
                                        = gc_final_unit_price_entered )             -- ���P�����͊����t���O��'Y'
                 OR ( in_report_type    = gc_report_type_3 ))                       -- ���[��ʁF3�̂Ƃ�
          AND   ilm.attribute1   BETWEEN  in_creat_date_from                        -- �p�����[�^�̐�������
                                 AND NVL( in_creat_date_to, gc_max_date_d )         -- �L���ȃf�[�^
          AND   xnpt.aracha_quantity    > 0                                         -- ����0�͎���f�[�^�ׁ̈A���O
          GROUP BY xilv.segment1                                                    -- ���ɐ�
                  ,xilv.description                                                 -- ���ɐ於
                  ,xnpt.aracha_item_code                                            -- �i��
                  ,ximv.item_short_name                                             -- �i��
        UNION ALL
          -- *** ���Y���i�ڏ��̃f�[�^�擾 ***
          SELECT byproduct.location_code                  AS location_code          -- ���ɐ�
                ,byproduct.location_name                  AS location_name          -- ���ɐ於
                ,gc_item_class_fuku                       AS item_class             -- �敪�i���Y���j�Œ�
                ,byproduct.item_code                      AS item_code              -- �i��
                ,byproduct.item_name                      AS item_name              -- �i��
                ,SUM( byproduct.quantity )                AS quantity               -- ����
                ,SUM( byproduct.amount )                  AS stock_amount           -- �݌ɋ��z
                ,gc_bypro_default_num                     AS aracha_amount          -- �������z
                ,gc_bypro_default_num                     AS collect_quantity       -- �W�א���
                ,gc_bypro_default_num                     AS collect_amount         -- �W�׋��z
                ,gc_bypro_default_num                     AS receive_quantity       -- �������
                ,gc_bypro_default_num                     AS receive_amount         -- ������z
                ,gc_bypro_default_num                     AS shipment_quantity      -- �o�א���
                ,gc_bypro_default_num                     AS shipment_amount        -- �o�׋��z
                ,gc_bypro_default_num                     AS nahama_total_quantity  -- ���t���v����
                ,gc_bypro_default_num                     AS namaha_total_amount    -- ���t���v���z
          FROM (
                 -- *** ���Y���P��� ***
                 SELECT xilv.segment1                     AS location_code          -- ���ɐ�
                       ,xilv.description                  AS location_name          -- ���ɐ於
                       ,xnpt.byproduct1_item_code         AS item_code              -- ���Y���P�i�ڃR�[�h
                       ,ximv.item_short_name              AS item_name              -- �i��
                       ,NVL( xnpt.byproduct1_quantity, 0) AS quantity               -- ���Y���P����
                       ,ROUND( NVL( xnpt.byproduct1_quantity, 0) * TO_NUMBER( NVL( ilm.attribute7, '0' ) ) ) 
                                                          AS amount                 -- ���Y���P���z
                 FROM   xxpo_namaha_prod_txns     xnpt                              -- ���t���сi�A�h�I���j
                       ,ic_lots_mst               ilm                               -- OPM���b�g�}�X�^
                       ,xxcmn_item_mst2_v         ximv                              -- OPM�i�ڏ��VIEW2
                       ,xxcmn_item_locations2_v   xilv                              -- OPM�ۊǏꏊ���VIEW2
                 ---------------------------------------------------------------------------------------------
                 -- ��������
                 WHERE xnpt.byproduct1_item_id  = ilm.item_id
                 AND   xnpt.byproduct1_lot_id   = ilm.lot_id
                 AND   xnpt.byproduct1_item_id  = ximv.item_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                     AND NVL( ximv.end_date_active, gd_max_date )
                 AND   xnpt.location_id         = xilv.inventory_location_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                     AND NVL( xilv.date_to, gd_max_date )
                 ---------------------------------------------------------------------------------------------
                 -- ���o����
                 AND   ((    in_report_type     = gc_report_type_4                  -- ���[��ʁF4�̂Ƃ�
                         AND xnpt.final_unit_price_entered_flg
                                                = gc_final_unit_price_entered )     -- ���P�����͊����t���O��'Y'
                        OR ( in_report_type     = gc_report_type_3 ))               -- ���[��ʁF3�̂Ƃ�
                 AND   ilm.attribute1    BETWEEN  in_creat_date_from                -- �p�����[�^�̐�������
                                         AND NVL( in_creat_date_to, gc_max_date_d ) -- �L���ȃf�[�^
                 AND   xnpt.aracha_quantity     > 0                                 -- ����0�͎���f�[�^�ׁ̈A���O
                 AND   xnpt.byproduct1_quantity > 0                                 -- ����0�͎���f�[�^�ׁ̈A���O
               UNION ALL
               -- *** ���Y���Q��� ***
                 SELECT xilv.segment1                     AS location_code          -- ���ɐ�
                       ,xilv.description                  AS location_name          -- ���ɐ於
                       ,xnpt.byproduct2_item_code         AS item_code              -- ���Y���Q�i�ڃR�[�h
                       ,ximv.item_short_name              AS item_name              -- �i��
                       ,NVL( xnpt.byproduct2_quantity, 0) AS quantity               -- ���Y���Q����
                       ,ROUND( NVL( xnpt.byproduct2_quantity, 0) * TO_NUMBER( NVL( ilm.attribute7, '0' ) ) ) 
                                                          AS amount                 -- ���Y���Q���z
                 FROM   xxpo_namaha_prod_txns     xnpt                              -- ���t���сi�A�h�I���j
                       ,ic_lots_mst               ilm                               -- OPM���b�g�}�X�^
                       ,xxcmn_item_mst2_v         ximv                              -- OPM�i�ڏ��VIEW2
                       ,xxcmn_item_locations2_v   xilv                              -- OPM�ۊǏꏊ���VIEW2
                 ---------------------------------------------------------------------------------------------
                 -- ��������
                 WHERE xnpt.byproduct2_item_id  = ilm.item_id
                 AND   xnpt.byproduct2_lot_id   = ilm.lot_id
                 AND   xnpt.byproduct2_item_id  = ximv.item_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                     AND NVL( ximv.end_date_active, gd_max_date )
                 AND   xnpt.location_id         = xilv.inventory_location_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                     AND NVL( xilv.date_to, gd_max_date )
                 ---------------------------------------------------------------------------------------------
                 -- ���o����
                 AND   ((    in_report_type     = gc_report_type_4                  -- ���[��ʁF4�̂Ƃ�
                         AND xnpt.final_unit_price_entered_flg
                                                = gc_final_unit_price_entered )     -- ���P�����͊����t���O��'Y'
                        OR ( in_report_type     = gc_report_type_3 ))               -- ���[��ʁF3�̂Ƃ�
                 AND   ilm.attribute1    BETWEEN  in_creat_date_from                -- �p�����[�^�̐�������
                                         AND NVL( in_creat_date_to, gc_max_date_d ) -- �L���ȃf�[�^
                 AND   xnpt.aracha_quantity     > 0                                 -- ����0�͎���f�[�^�ׁ̈A���O
                 AND   xnpt.byproduct2_quantity > 0                                 -- ����0�͎���f�[�^�ׁ̈A���O
               UNION ALL
               -- *** ���Y���R��� ***
                 SELECT xilv.segment1                     AS location_code          -- ���ɐ�
                       ,xilv.description                  AS location_name          -- ���ɐ於
                       ,xnpt.byproduct3_item_code         AS item_code              -- ���Y���R�i�ڃR�[�h
                       ,ximv.item_short_name              AS item_name              -- �i��
                       ,NVL( xnpt.byproduct3_quantity, 0) AS quantity               -- ���Y���R����
                       ,ROUND( NVL( xnpt.byproduct3_quantity, 0) * TO_NUMBER( NVL( ilm.attribute7, '0' ) ) ) 
                                                          AS amount                 -- ���Y���R���z
                 FROM   xxpo_namaha_prod_txns     xnpt                              -- ���t���сi�A�h�I���j
                       ,ic_lots_mst               ilm                               -- OPM���b�g�}�X�^
                       ,xxcmn_item_mst2_v         ximv                              -- OPM�i�ڏ��VIEW2
                       ,xxcmn_item_locations2_v   xilv                              -- OPM�ۊǏꏊ���VIEW2
                 ---------------------------------------------------------------------------------------------
                 -- ��������
                 WHERE xnpt.byproduct3_item_id  = ilm.item_id
                 AND   xnpt.byproduct3_lot_id   = ilm.lot_id
                 AND   xnpt.byproduct3_item_id  = ximv.item_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN ximv.start_date_active
                                                                     AND NVL( ximv.end_date_active, gd_max_date )
                 AND   xnpt.location_id         = xilv.inventory_location_id
                 AND   FND_DATE.STRING_TO_DATE( ilm.attribute1, gc_char_d_format ) BETWEEN xilv.date_from
                                                                     AND NVL( xilv.date_to, gd_max_date )
                 ---------------------------------------------------------------------------------------------
                 -- ���o����
                 AND   ((    in_report_type     = gc_report_type_4                  -- ���[��ʁF4�̂Ƃ�
                         AND xnpt.final_unit_price_entered_flg
                                                = gc_final_unit_price_entered )     -- ���P�����͊����t���O��'Y'
                        OR ( in_report_type     = gc_report_type_3 ))               -- ���[��ʁF3�̂Ƃ�
                 AND   ilm.attribute1    BETWEEN  in_creat_date_from                -- �p�����[�^�̐�������
                                         AND NVL( in_creat_date_to, gc_max_date_d ) -- �L���ȃf�[�^
                 AND   xnpt.aracha_quantity     > 0                                 -- ����0�͎���f�[�^�ׁ̈A���O
                 AND   xnpt.byproduct3_quantity > 0                                 -- ����0�͎���f�[�^�ׁ̈A���O
               )  byproduct
          GROUP BY byproduct.location_code                                          -- ���ɐ�
                  ,byproduct.location_name                                          -- ���ɐ於
                  ,byproduct.item_code                                              -- �i��
                  ,byproduct.item_name                                              -- �i��
        ) cmd
      ORDER BY cmd.location_code                                                    -- ���ɐ�
              ,cmd.item_class                                                       -- �敪
              ,to_number( cmd.item_code )                                           -- �i��
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
   * Description      : �w�l�k�f�[�^�쐬(C-4)
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
    lc_break_init  VARCHAR2(5)  := '*****';
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_loc_code    mtl_item_locations.segment1%TYPE; -- ���ɑq�ɃR�[�h
    lv_item_class  VARCHAR2(6);                      -- �敪
    -- ���Ԃ̏o�͕ҏW�p
    lv_date_fromto VARCHAR2(30);
--
    -- *** ���[�J���E��O���� ***
    no_data_expt   EXCEPTION ;   -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
    -- =====================================================
    -- �u���C�N�L�[������
    -- =====================================================
    lv_loc_code   := lc_break_init;
    lv_item_class := lc_break_init;
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
    -- �q�ɂf�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- ���[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- ���[�^�C�g��
    IF ( ir_param.iv_report_type = gc_report_type_3 ) THEN
      -- ���[��ʁF3�̂Ƃ�
      insert_xml_plsql_table(iox_xml_data, 'report_title', gc_report_title_kari, 
                                                             gc_tag_type_data, gc_tag_value_type_char);
    ELSIF ( ir_param.iv_report_type = gc_report_type_4 ) THEN
      -- ���[��ʁF4�̂Ƃ�
      insert_xml_plsql_table(iox_xml_data, 'report_title', gc_report_title, 
                                                             gc_tag_type_data, gc_tag_value_type_char);
    ELSE
      -- ���[��ʁF3�A4�ȊO�̂Ƃ�
      insert_xml_plsql_table(iox_xml_data, 'report_title', NULL, 
                                                             gc_tag_type_data, gc_tag_value_type_char);
    END IF;
    -- ���[�h�c
    insert_xml_plsql_table(iox_xml_data, 'report_id', gc_report_id, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- ���{��
    insert_xml_plsql_table(iox_xml_data, 'exec_date', TO_CHAR( gd_exec_date, gc_char_dt_format ), 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- ����
    -- ���Ԃ̕ҏW
    lv_date_fromto := SUBSTRB( ir_param.iv_creat_date_from, 1, 4) || gc_out_year  ||
                      SUBSTRB( ir_param.iv_creat_date_from, 6, 2) || gc_out_month ||
                      SUBSTRB( ir_param.iv_creat_date_from, 9, 2) || gc_out_day   || gc_out_part;
    IF ( ir_param.iv_creat_date_to IS NOT NULL ) THEN
      lv_date_fromto := lv_date_fromto ||
                        SUBSTRB( ir_param.iv_creat_date_to, 1, 4) || gc_out_year  ||
                        SUBSTRB( ir_param.iv_creat_date_to, 6, 2) || gc_out_month ||
                        SUBSTRB( ir_param.iv_creat_date_to, 9, 2) || gc_out_day;
    END IF;
    insert_xml_plsql_table(iox_xml_data, 'date_fromto', lv_date_fromto, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �S������
    insert_xml_plsql_table(iox_xml_data, 'department_code', gv_department_code, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- �S����
    insert_xml_plsql_table(iox_xml_data, 'department_name', gv_department_name, 
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
      -- ���ɑq�Ƀu���C�N
      -- =====================================================
      -- ���ɑq�ɂ��؂�ւ�����Ƃ�
      IF ( gt_main_data(i).location_code <> lv_loc_code ) THEN
        -- -----------------------------------------------------
        -- ���ɑq�ɖ��ׂf�I���^�O�o��
        -- -----------------------------------------------------
        -- �ŏ��̃��R�[�h�̂Ƃ��͏o�͂��Ȃ�
        IF ( lv_loc_code <> lc_break_init ) THEN
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
        insert_xml_plsql_table(iox_xml_data, 'location_code', SUBSTRB( gt_main_data(i).location_code, 1, 4 ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ���ɑq�ɐ於
        insert_xml_plsql_table(iox_xml_data, 'location_name', SUBSTRB( gt_main_data(i).location_name, 1, 20 ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- �敪���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- ���ɑq�Ƀu���C�N�L�[�X�V
        -- -----------------------------------------------------
        lv_loc_code := gt_main_data(i).location_code;
        -- -----------------------------------------------------
        -- �敪�u���C�N�L�[�X�V
        -- -----------------------------------------------------
        lv_item_class := gt_main_data(i).item_class;
      END IF;
--
      -- =====================================================
      -- �敪�u���C�N
      -- =====================================================
      -- �敪���؂�ւ�����Ƃ�
      IF ( gt_main_data(i).item_class <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �敪���ׂf�I���^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- �敪���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- �敪�u���C�N�L�[�X�V
        -- -----------------------------------------------------
        lv_item_class := gt_main_data(i).item_class;
      END IF;
--
      -- -----------------------------------------------------
      -- �敪���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- �敪���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- �敪
      insert_xml_plsql_table(iox_xml_data, 'item_class', gt_main_data(i).item_class, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �i�ځi�R�[�h�j
      insert_xml_plsql_table(iox_xml_data, 'item_code', SUBSTRB( TO_CHAR( gt_main_data(i).item_code ), 1, 7 ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �i�ځi���j
      insert_xml_plsql_table(iox_xml_data, 'item_name', gt_main_data(i).item_name, 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ����
      insert_xml_plsql_table(iox_xml_data, 'quantity', TO_CHAR( gt_main_data(i).quantity ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �݌ɋ��z
      insert_xml_plsql_table(iox_xml_data, 'stock_amount', TO_CHAR( gt_main_data(i).stock_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �������z
      insert_xml_plsql_table(iox_xml_data, 'aracha_amount', TO_CHAR( gt_main_data(i).aracha_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �W�א���
      insert_xml_plsql_table(iox_xml_data, 'collect_quantity', TO_CHAR( gt_main_data(i).collect_quantity ),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �W�׋��z
      insert_xml_plsql_table(iox_xml_data, 'collect_amount', TO_CHAR( gt_main_data(i).collect_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �������
      insert_xml_plsql_table(iox_xml_data, 'receive_quantity', TO_CHAR( gt_main_data(i).receive_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ������z
      insert_xml_plsql_table(iox_xml_data, 'receive_amount', TO_CHAR( gt_main_data(i).receive_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- �o�א���
      insert_xml_plsql_table(iox_xml_data, 'shipment_quantity', TO_CHAR( gt_main_data(i).shipment_quantity ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- �o�׋��z
      insert_xml_plsql_table(iox_xml_data, 'shipment_amount', TO_CHAR( gt_main_data(i).shipment_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
--
      -- ���t���v����
      insert_xml_plsql_table(iox_xml_data, 'nahama_total_quantity', TO_CHAR( gt_main_data(i).nahama_total_quantity),
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- ���t���v���z
      insert_xml_plsql_table(iox_xml_data, 'namaha_total_amount', TO_CHAR( gt_main_data(i).namaha_total_amount ), 
                                                          gc_tag_type_data, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- �敪���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, '/g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    -- -----------------------------------------------------
    -- �敪���ׂf�I���^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
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
      iv_report_type        IN     VARCHAR2         --   01 : ���[���
     ,iv_creat_date_from    IN     VARCHAR2         --   02 : ��������FROM
     ,iv_creat_date_to      IN     VARCHAR2         --   03 : ��������TO
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
    -- �ő���t�ݒ�
    gd_max_date                     := FND_DATE.STRING_TO_DATE( gc_max_date_d, gc_char_d_format );
--
    -- =====================================================
    -- �O����(C-2)
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
    -- ���[�f�[�^�o��(C-3,4)
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
    -- �w�l�k�o��(C-4)
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <report_title>' || gc_report_title || '</report_title>' ) ;
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
     ,iv_report_type        IN     VARCHAR2         -- 01 : ���[���
     ,iv_creat_date_from    IN     VARCHAR2         -- 02 : ��������FROM
     ,iv_creat_date_to      IN     VARCHAR2         -- 03 : ��������TO
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
END xxpo710002c ;
/