CREATE OR REPLACE PACKAGE XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(spec)
 * Description      : �����v��
 * MD.050           : �����v�� MD050_COP_006_A01
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/12/01    1.0   M.Hokkanji       �V�K�쐬
 *  2010/02/03    1.1   Y.Goto           E_�{�ғ�_01222
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2                 --   �G���[���b�Z�[�W #�Œ�#
    ,retcode                OUT    VARCHAR2                 --   �G���[�R�[�h     #�Œ�#
    ,iv_planning_date_from  IN     VARCHAR2                 -- 1.�v�旧�Ċ���(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.�v�旧�Ċ���(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.�o�׌v��敪
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.�o�׃y�[�X�v�����(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.�o�׃y�[�X�v�����(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.�o�ח\������(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.�o�ח\������(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.�o�׈����ϓ�
    ,iv_item_code           IN     VARCHAR2                 -- 9.�i�ڃR�[�h
--20100203_Ver1.1_E_�{�ғ�_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.�ғ�����
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.�݌ɓ��������l
--20100203_Ver1.1_E_�{�ғ�_01222_SCS.Goto_ADD_END
  );
END XXCOP006A01C;
/
