/*============================================================================
* �t�@�C���� : XxwshReserveLotAMImpl
* �T�v����   : �������b�g����:�o�^�A�v���P�[�V�������W���[��
* �o�[�W���� : 1.9
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  �k�������v     �V�K�쐬
* 2008-08-07 1.1  ��r�@���     �����ύX�v��#166,#173
* 2008-10-07 1.2  �ɓ��ЂƂ�     �����e�X�g�w�E240�Ή�
* 2008-10-22 1.3  ��r�@���     �����e�X�g�w�E194�Ή�
* 2008-10-24 1.4  ��r�@���     TE080_BPO_600 No22
* 2008-12-10 1.5  �ɓ��ЂƂ�     �{�ԏ�Q#587�Ή�
* 2008-12-11 1.6  �ɓ��ЂƂ�     �{�ԏ�Q#675�Ή�
* 2008-12-25 1.7  ��r�@���     �{�ԏ�Q#771�Ή�
* 2009-01-22 1.8  �ɓ��ЂƂ�     �{�ԏ�Q#1000�Ή�
* 2009-01-26 1.9  �ɓ��ЂƂ�     �{�ԏ�Q#936�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

import java.math.BigDecimal;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.AttributeDef;
import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * ���������b�g���͉�ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE �k���� ���v
 * @version 1.9
 ***************************************************************************
 */
 
public class XxwshReserveLotAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshReserveLotAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxwsh.xxwsh920002j.server", "XxwshReserveLotAMLocal");
  }

  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   * @param params �����p�����[�^�pHashMap
   ***************************************************************************
   */
  public void initialize(
    HashMap params
  )
  {

    // ******************************************* //
    // * �y�[�W���C�A�E�g���[�W����PVO ��s�擾       * //
    // ******************************************* //
    OAViewObject PVO = getXxwshPageLayoutPVO1();
    OARow pvoRow     = null;
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (PVO.getFetchedRowCount() == 0)
    {    
      PVO.setMaxFetchSize(0);
      // 1�s�ڂ��쐬
      PVO.insertRow(PVO.createRow());
      // 1�s�ڂ��擾
      pvoRow = (OARow)PVO.first();
      // �L�[�ɒl���Z�b�g
      pvoRow.setAttribute("RowKey", new Number(1));
    }
    // PVO1�s�ڂ��擾
    pvoRow = (OARow)PVO.first();
    // *********************** //
    // *  �p�����[�^�`�F�b�N * //
    // *********************** //
    checkParams(params);

    // *********************** //
    // *  ���ڐ���            * //
    // *********************** //
    itemControl(XxcmnConstants.STRING_N, params);

    // **************************************** //
    // * ���������\�����[�W�����f�[�^�擾����      * //
    // *****************************************//
    getSearchData(params);
    
    // *********************************************** //
    // * �莝���ʈ����\���ꗗ���[�W����VO ��������       * //
    // *********************************************** //
    // ���������\�����[�W�������擾
    OAViewObject hvo = getXxwshSearchVO1();
    // ���������\�����[�W�����̈�s�ڂ��擾
    OARow hRow       = (OARow)hvo.first();
    // ���׏�񃊁[�W�������擾
    OAViewObject lvo = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lRow       = (OARow)lvo.first();
    HashMap data     = new HashMap();
    // �����ɕK�v�ȍ��ڂ��Z�b�g
    data.put("ItemId",                    hRow.getAttribute("ItemId"));                     // �i��ID
    data.put("InputInventoryLocationId"  ,lRow.getAttribute("InputInventoryLocationId"));   // �ۊǑq��ID
// 2008-12-25 D.Nihei Add Start
    data.put("InputInventoryLocationCode",lRow.getAttribute("InputInventoryLocationCode")); // �ۊǑq�ɃR�[�h
// 2008-12-25 D.Nihei Add End
    data.put("DocumentTypeCode",          lRow.getAttribute("DocumentTypeCode"));           // �����^�C�v
    data.put("LocationRelCode",           lRow.getAttribute("LocationRelCode"));            // ���_���їL���敪
    data.put("ConvUnitUseKbn",            hRow.getAttribute("ConvUnitUseKbn"));             // ���o�Ɋ��Z�P�ʎg�p�敪
    data.put("CallPictureKbn",            hRow.getAttribute("CallPictureKbn"));             // �ďo��ʋ敪
    data.put("LotCtl",                    hRow.getAttribute("LotCtl"));                     // ���b�g�Ǘ��i
    data.put("DesignatedProductionDate",  lRow.getAttribute("DesignatedProductionDate"));   // �w�萻����
    data.put("LineId",                    lRow.getAttribute("LineId"));                     // ����ID
    data.put("ScheduleShipDate",          lRow.getAttribute("ScheduleShipDate"));           // �o�ח\���
    data.put("ProdClass",                 hRow.getAttribute("ProdClass"));                  // ���i�敪
    data.put("ItemClass",                 hRow.getAttribute("ItemClass"));                  // �i�ڋ敪
    data.put("NumOfCases",                hRow.getAttribute("NumOfCases"));                 // �P�[�X����
// 2008-12-25 D.Nihei Add Start
    data.put("FrequentWhseCode",          lRow.getAttribute("FrequentWhseCode"));           // ��\�q��
    data.put("MasterOrgId",               getOADBTransaction().getProfile("XXCMN_MASTER_ORG_ID"));        // �݌ɑg�DID
    data.put("MaxDate",                   getOADBTransaction().getProfile("XXCMN_MAX_DATE"));             // �ő���t
    data.put("DummyFrequentWhse",         getOADBTransaction().getProfile("XXCMN_DUMMY_FREQUENT_WHSE"));  // �_�~�[�q��
// 2008-12-25 D.Nihei Add End
    XxwshStockCanEncQtyVOImpl vo = getXxwshStockCanEncQtyVO1();
// 2008-12-25 D.Nihei Add Start
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
    } else
    {
      vo.first();
      OARow row = null;
      while (vo.getCurrentRow() != null)
      {
        row = (OARow)vo.getCurrentRow();
        row.remove();
        vo.next();
      }
    }
// 2008-12-25 D.Nihei Add End
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����������{
// 2008-12-25 D.Nihei Mod Start
//    vo.initQuery(data);
    // ���b�g�Ǘ��i�̏ꍇ
    if (XxcmnUtility.isEquals(new Number(1), hRow.getAttribute("LotCtl"))) 
    {
      XxwshReserveLotVOImpl lotVo = getXxwshReserveLotVO1();
      lotVo.initQuery(data);
      copyRows(lotVo, vo);
      
    // ���b�g�Ǘ��i�O�̏ꍇ
    } else 
    {
      XxwshReserveUnLotVOImpl unLotVo = getXxwshReserveUnLotVO1();
      unLotVo.initQuery(data);
      copyRows(unLotVo, vo);
      
    }
// 2008-12-25 D.Nihei Mod End
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̌�����0���̏ꍇ
// 2008-12-25 D.Nihei Mod Start
//    if ( vo.getRowCount() == 0)
    if ( vo.getFetchedRowCount() == 0 )
// 2008-12-25 D.Nihei Mod End
    {
      // �x���w������ʂ֖߂�{�^���ȊO���\��&������
      pvoRow.setAttribute("CancelRendered", Boolean.FALSE); // �ꊇ�����F��\��
      pvoRow.setAttribute("CalcRendered",   Boolean.FALSE); // �v�Z�F��\��
      pvoRow.setAttribute("ApplyDisabled",  Boolean.TRUE);  // �K�p�F����      
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̌������ꌏ�ȏ�̏ꍇ
    } else
    {
      // �莝�݌ɐ��E�����\���ꗗ���[�W������SQL�ŃZ�b�g�ł��Ȃ����ڂ��Z�b�g
      setStockCanEncQty();
    }
  }

  /***************************************************************************
   * �ΏۂƂȂ閾�׏�񃊁[�W�����̃r���[�I�u�W�F�N�g��Ԃ����\�b�h�ł��B
   * @return OAViewObject �ΏۂƂȂ閾�׏�񃊁[�W�����̃r���[�I�u�W�F�N�g
   ***************************************************************************
   */
  public OAViewObject getXxwshLineVO()
  {
    
    // *********************************************** //
    // * �莝���ʈ����\���ꗗ���[�W����VO ��������       * //
    // *********************************************** //
    // ���������\�����[�W�������擾
    OAViewObject hvo      = getXxwshSearchVO1();
    // ���������\�����[�W�����̈�s�ڂ��擾
    OARow hRow            = (OARow)hvo.first();
    String callPictureKbn = (String)hRow.getAttribute("CallPictureKbn"); // �ďo��ʋ敪

    // �ďo��ʋ敪���o�׈˗����͉�ʋN���̏ꍇ
    if ( XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      return getXxwshLineShipVO1();

    // �ďo��ʋ敪���x���w���쐬��ʋN���̏ꍇ
    } else if ( XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
    {
      return getXxwshLineProdVO1();

    // �ďo��ʋ敪���ړ��˗�/�w�����͉�ʋN���̏ꍇ
    } else if ( XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      return getXxwshLineMoveVO1();
    } else
    {
      return null;
    }
  }
  
  /***************************************************************************
   * �p�����[�^�`�F�b�N���s�����\�b�h�ł��B
   * @param  params - �p�����[�^
   * @throws OAException   - OA��O
   ***************************************************************************
   */
  public void checkParams(
    HashMap params
    ) throws OAException
  {
    // �p�����[�^�擾
    String callPictureKbn   = (String)params.get("callPictureKbn");   // �ďo��ʋ敪
    String lineId           = (String)params.get("LineId");           // ����ID
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // ���׍X�V����
    String exeKbn           = (String)params.get("exeKbn");           // �N���敪   

    // �ďo��ʋ敪���ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(callPictureKbn))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_CALL_PICTURE_KBN) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }

    // ����ID���ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(lineId))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_LINE_ID) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }

    // ���׍X�V�������ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(lineUpdateDate))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }

    // �w�b�_�X�V�������ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(headerUpdateDate))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }
    // ���׍X�V�����̏�����YYYY/MM/DD HH24:MI:SS�łȂ��ꍇ
    if (!XxcmnUtility.chkDateFormat(
      getOADBTransaction(),
      lineUpdateDate,
      XxwshConstants.DATE_FORMAT))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12903, 
        tokens);     
    }
    
    // �w�b�_�X�V�����̏�����YYYY/MM/DD HH24:MI:SS�łȂ��ꍇ
    if(!XxcmnUtility.chkDateFormat(
      getOADBTransaction(),
      headerUpdateDate,
      XxwshConstants.DATE_FORMAT))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12903, 
        tokens);     
    }

    // �ďo��ʋ敪��2:�x���w���쐬��ʂŁA�N���敪���ݒ肳��Ă��Ȃ��ꍇ
    if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn)
      && XxcmnUtility.isBlankOrNull(exeKbn))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);

      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(
                                XxwshConstants.TOKEN_PARM_NAME,
                                XxwshConstants.TOKEN_NAME_EXE_KBN) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12904, 
        tokens);        
    }
  }

  /***************************************************************************
   * ���ڐ�����s�����\�b�h�ł��B
   * @param  errFlag   - Y:�G���[�̏ꍇ(�߂�{�^���ȊO�s�\)
   *                          - N:����
   * @param  params    - ���̓p�����[�^
   * @throws OAException      - OA��O
   ***************************************************************************
   */
  public void itemControl(
    String errFlag,
    HashMap params
    ) throws OAException
  {
    // PVO�擾
    OAViewObject pvo = getXxwshPageLayoutPVO1();   
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // �f�t�H���g�l�ݒ�
    pvoRow.setAttribute("ReturnRendered",  Boolean.TRUE);  // �x���x����ʂ֖߂�F�\��
    pvoRow.setAttribute("CancelRendered",  Boolean.TRUE);  // �ꊇ�����F�\��
    pvoRow.setAttribute("CalcRendered",    Boolean.TRUE);  // �v�Z�F�\��
    pvoRow.setAttribute("ApplyDisabled",   Boolean.FALSE); // �K�p�F�L��

    // �G���[�̏ꍇ(�߂�{�^���ȊO����s�\)
    if (XxcmnConstants.STRING_Y.equals(errFlag))
    {
      pvoRow.setAttribute("ReturnRendered", Boolean.FALSE); // �x���x����ʂ֖߂�F��\��
      pvoRow.setAttribute("CancelRendered", Boolean.FALSE); // �ꊇ�����F��\��
      pvoRow.setAttribute("CalcRendered",   Boolean.FALSE); // �v�Z�F��\��
      pvoRow.setAttribute("ApplyDisabled",  Boolean.TRUE);  // �K�p�F����

    // �G���[�łȂ��ꍇ      
    } else
    {
      // �ďo��ʋ敪���擾
      String callPictureKbn  = (String)params.get("callPictureKbn");   // �ďo��ʋ敪
      //�ďo��ʋ敪��2:�x���w���쐬��ʈȊO�̏ꍇ
      if (!XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
      {
        pvoRow.setAttribute("ReturnRendered", Boolean.FALSE); // �x���x����ʂ֖߂�F��\��     
      }
    }
  }

  /***************************************************************************
   * �������\�����[�W�����ɒl���擾���Z�b�g���郁�\�b�h�ł�
   * @param  params - ���̓p�����[�^
   * @throws OAException   - OA�G���[
   ***************************************************************************
   */
  public void getSearchData(
    HashMap params
    ) throws OAException
  {
    // ���̓p�����[�^�擾
    String callPictureKbn   = (String)params.get("callPictureKbn");   // �ďo��ʋ敪
    String lineId           = (String)params.get("LineId");           // ����ID
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // ���׍X�V����
    String exeKbn           = (String)params.get("exeKbn");           // �N���敪   
    // ���׏�񃊁[�W�������R�[�h�擾�p
    OARow lrow              = null;

    // �ďo��ʋ敪���o�׈˗����͉�ʋN���̏ꍇ
    if ( XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      // ���׏�񃊁[�W����(�o��)���擾
      XxwshLineShipVOImpl lvo  = getXxwshLineShipVO1();
      // �������{
      lvo.initQuery(lineId);

      // ���׏�񃊁[�W�������擾�ł��Ȃ������ꍇ
      if (lvo.getRowCount() == 0)
      {
        // ���ڐ���(�߂�{�^���ȊO��\��
        itemControl(XxcmnConstants.STRING_Y,params);
      
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10500); 
      }
      // ��s�ڂ��擾
      lrow = (OARow)lvo.first();
    // �ďo��ʋ敪���x���w���쐬��ʋN���̏ꍇ
    } else if ( XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
    {
      // ���׏�񃊁[�W����(�x��)���擾
      XxwshLineProdVOImpl lvo  = getXxwshLineProdVO1();
      // �������{
      lvo.initQuery(lineId);
      // ���׏�񃊁[�W�������擾�ł��Ȃ������ꍇ
      if (lvo.getRowCount() == 0)
      {
        // ���ڐ���(�߂�{�^���ȊO��\��
        itemControl(XxcmnConstants.STRING_Y,params);
      
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10500); 
      }
      // ��s�ڂ��擾
      lrow = (OARow)lvo.first();

    // �ďo��ʋ敪���ړ��˗�/�w�����͉�ʋN���̏ꍇ
    } else if ( XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // ���׏�񃊁[�W����(�ړ�)���擾
      XxwshLineMoveVOImpl lvo  = getXxwshLineMoveVO1();
      // �������{
      lvo.initQuery(lineId);
      // ���׏�񃊁[�W�������擾�ł��Ȃ������ꍇ
      if (lvo.getRowCount() == 0)
      {
        // ���ڐ���(�߂�{�^���ȊO��\��
        itemControl(XxcmnConstants.STRING_Y,params);
      
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10500); 
      }
      // ��s�ڂ��擾
      lrow = (OARow)lvo.first();
    }

    // �����ɕK�v�ȍ��ڂ��擾
    String itemCode                = (String)lrow.getAttribute("ItemCode");                // �i�ڃR�[�h
    Date scheduleShipDate          = (Date)lrow.getAttribute("ScheduleShipDate");          // �o�ɗ\���
    String sumReservedQuantityItem = (String)lrow.getAttribute("SumReservedQuantityItem"); // ��������(�i�ڒP��)
    String instructQty             = (String)lrow.getAttribute("InstructQty");             // �w������(�i�ڒP��)


    // ���������\�����[�W�������擾
    XxwshSearchVOImpl hvo   = getXxwshSearchVO1();
    // �������{
    hvo.initQuery(
      itemCode,
      scheduleShipDate,
      callPictureKbn,
      instructQty,
      sumReservedQuantityItem);
    // ���������\�����[�W�������擾�ł��Ȃ������ꍇ
    if ( hvo.getRowCount() == 0)
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y, params);

      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500); 
    }
    // 1�s�ڂ��擾
    OARow hrow = (OARow)hvo.first();

    // ���͍��ڂ����������\�����[�W�����ɃZ�b�g
    hrow.setAttribute("LineId",           lineId);           // ����ID
    hrow.setAttribute("CallPictureKbn",   callPictureKbn);   // �ďo��ʋ敪
    hrow.setAttribute("HeaderUpdateDate", headerUpdateDate); // �w�b�_�ŏI�X�V��
    hrow.setAttribute("LineUpdateDate",   lineUpdateDate);   // ���׍ŏI�X�V��
    hrow.setAttribute("ExeKbn",           exeKbn);           // �N���敪

    // ���׏��\�����[�W�����ŉ�ʕ\���ɕK�v�ȍ��ڂ����������\�����[�W�����ɃZ�b�g
    hrow.setAttribute("DesignatedProductionDate", lrow.getAttribute("DesignatedProductionDate")); // �w�萻����
    hrow.setAttribute("RequestNo",                lrow.getAttribute("RequestNo"));                // �`�[No
    hrow.setAttribute("SumReservedQuantityItem",  lrow.getAttribute("SumReservedQuantityItem"));  // �������ʍ��v(�i�ڒP��)
    hrow.setAttribute("ItemCode",                 itemCode);                                      // �`�[No

  }
  
  /***************************************************************************
   * �莝�݌ɐ��E�����\���ꗗ���[�W�����̊e���ڂɒl���Z�b�g���܂��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void setStockCanEncQty() throws OAException
  {
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����擾
    OAViewObject vo = getXxwshStockCanEncQtyVO1();
    // �莝�݌ɐ��E�����\���ꗗ���[�W�������擾����ϐ���錾
    OARow row       = null;
    // �莝�݌ɐ��E�����\���ꗗ���[�W������1�s�ڂ��Z�b�g
    vo.first();
    // �S�����[�v
    while (vo.getCurrentRow() != null )
    {
      // �����Ώۍs���擾
      row = (OARow)vo.getCurrentRow();

      // ��������(���Z��)�\�����ۑ��p�Ɉ�������(���Z��)�̒l���Z�b�g
      row.setAttribute(
        "ShowActualQuantityBk",
        row.getAttribute(
          "ShowActualQuantity"));

      // �������ʕ\�����ۑ��p�Ɉ������ʂ̒l���Z�b�g
      row.setAttribute(
        "ActualQuantityBk",
        row.getAttribute(
          "ActualQuantity"));

      // ���̃��R�[�h��
      vo.next();
    }
  }

  /***************************************************************************
   * �v�Z�������s�����\�b�h�ł��B
   * @throws OAException -OA��O
   ***************************************************************************
  */
  public void calcProcess() throws OAException
  {
    // ���������\�����[�W�������擾
    OAViewObject hvo              = getXxwshSearchVO1();
    // ���������\�����[�W�����̈�s�ڂ��擾
    OARow hrow                    = (OARow)hvo.first();
    String convUnitUseKbn         = (String)hrow.getAttribute("ConvUnitUseKbn"); // ���o�Ɋ��Z�P�ʎg�p�敪
    String numOfCases             = (String)hrow.getAttribute("NumOfCases");     // �P�[�X����
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����擾
    OAViewObject vo               = getXxwshStockCanEncQtyVO1();
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̃��R�[�h���Z�b�g���邽�߂̕ϐ���錾
    OARow row                     = null;
    String showActualQuantity     = null;                                        // ��������(���Z��)
    BigDecimal setActualQuantity  = null;                                        // ��������(VO�Z�b�g�p)
// 2008-12-10 H.Itou Mod Start
//    double actualQuantity        = 0;                                            // ��������
//    double sumActualQuantity     = 0;                                            // �������ʍ��v(���Z��)
//    double sumActualQuantityItem = 0;                                            // �������ʍ��v
    BigDecimal actualQuantity        = new BigDecimal(0);                        // ��������
    BigDecimal sumActualQuantity     = new BigDecimal(0);                        // �������ʍ��v(���Z��)
    BigDecimal sumActualQuantityItem = new BigDecimal(0);                        // �������ʍ��v
//
    ArrayList exceptions          = new ArrayList(100);                          // �G���[���b�Z�[�W�i�[�z��

    // �莝�݌ɐ��E�����\���ꗗ���[�W����1�s�ڂ��擾
    vo.first();
    // �S�����[�v
    while (vo.getCurrentRow() != null )
    {
      // �����Ώۍs���擾
      row                = (OARow)vo.getCurrentRow();
      showActualQuantity = (String)row.getAttribute("ShowActualQuantity"); // ��������(���Z��)

      // �l���ݒ肳��Ă��Ȃ��ꍇ
      if (XxcmnUtility.isBlankOrNull(showActualQuantity))
      {
        // �G���[���b�Z�[�W�z��ɕK�{�G���[���b�Z�[�W���i�[
        exceptions.add( 
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,          
            vo.getName(),
            row.getKey(),
            "ShowActualQuantity",
            showActualQuantity,
            XxcmnConstants.APPL_XXWSH,         
            XxwshConstants.XXWSH12911));
      // ���l(999999999.999)�łȂ��ꍇ�̓G���[
      } else if (!XxcmnUtility.chkNumeric(showActualQuantity, 9, 3)) 
      {
        // �G���[���b�Z�[�W�z��ɏ����G���[���b�Z�[�W���i�[
        exceptions.add( 
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,          
            vo.getName(),
            row.getKey(),
            "ShowActualQuantity",
            showActualQuantity,
            XxcmnConstants.APPL_XXWSH,         
            XxwshConstants.XXWSH12902));
      // �}�C�i�X�l�̓G���[
      } else if (!XxcmnUtility.chkCompareNumeric(2, showActualQuantity, "0"))
      {
        // �G���[���b�Z�[�W�z��Ƀ}�C�i�X�G���[���b�Z�[�W���i�[
        exceptions.add( 
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,          
            vo.getName(),
            row.getKey(),
            "ShowActualQuantity",
            showActualQuantity,
            XxcmnConstants.APPL_XXWSH,         
            XxwshConstants.XXWSH12905));
      } else
      {

        // ���Z�Ώۂ̏ꍇ���Z��������
        if (XxwshConstants.CONV_UNIT_USE_KBN_INCLUDE.equals(convUnitUseKbn))
        {
          // �������ʂɈ�������(���Z��) * �P�[�X�������Z�b�g
// 2008-12-10 H.Itou Mod Start
//          actualQuantity = Double.parseDouble(showActualQuantity) * Double.parseDouble(numOfCases);
          actualQuantity = XxcmnUtility.bigDecimalValue(showActualQuantity); // ��������
          actualQuantity = actualQuantity.multiply(XxcmnUtility.bigDecimalValue(numOfCases));
// 2008-12-10 H.Itou Mod End
        } else
        {
          // �������ʂɈ�������(���Z��)���Z�b�g
// 2008-12-10 H.Itou Mod Start
//          actualQuantity = Double.parseDouble(showActualQuantity);
          actualQuantity = XxcmnUtility.bigDecimalValue(showActualQuantity); // ��������
// 2008-12-10 H.Itou Mod End
        }
// 2008-12-10 H.Itou Mod Start
//        // �莝�݌ɐ��E�����\���ꗗ���[�W�����Ɋ��Z���������l���Z�b�g���邽�߁ABigDecimal�Ɉꎞ�I�ɃZ�b�g
//        setActualQuantity =  new BigDecimal(String.valueOf(actualQuantity));
        // �莝�݌ɐ��E�����\���ꗗ���[�W����.�������ʂɃZ�b�g
//        row.setAttribute("ActualQuantity",setActualQuantity);
        row.setAttribute("ActualQuantity",actualQuantity);
// 2008-12-10 H.Itou Mod Start
        // ��������(���Z��)�̍��v�l���Z�o
// 2008-12-10 H.Itou Mod Start
//        sumActualQuantity     = sumActualQuantity + Double.parseDouble(showActualQuantity);
        sumActualQuantity = sumActualQuantity.add(XxcmnUtility.bigDecimalValue(showActualQuantity));
// 2008-12-10 H.Itou Mod End
        // �������ʂ̍��v�l���Z�o
// 2008-12-10 H.Itou Mod Start
//        sumActualQuantityItem = sumActualQuantityItem + actualQuantity;
        sumActualQuantityItem = sumActualQuantityItem.add(actualQuantity);
// 2008-12-10 H.Itou Mod End
      }
      // ���̍s�Ɉړ�
      vo.next();
    }

    //�G���[������ꍇ���b�Z�[�W���o��
    if (exceptions.size() > 0)
    {
      // �G���[���b�Z�[�W����ʂɏo��
      OAException.raiseBundledOAException(exceptions);

    //�G���[���Ȃ��ꍇ���Z�����l�����������\�����[�W�����ɃZ�b�g
    } else
    {
      // ���������\�����[�W�����Ɉ������ʍ��v(���Z��)���Z�b�g
// 2008-12-10 H.Itou Mod Start
//      hrow.setAttribute("SumReservedQuantity",    XxcmnUtility.formConvNumber(new Double(sumActualQuantity), 9, 3, true));
      hrow.setAttribute("SumReservedQuantity",  String.valueOf(sumActualQuantity));
// 2008-12-10 H.Itou Mod End
      // ���������\�����[�W�����Ɉ������ʍ��v���Z�b�g
      hrow.setAttribute("SumReservedQuantityItem",String.valueOf(sumActualQuantityItem));
    }
  }

  /***************************************************************************
   * �v�Z�{�^���������̏������s�����\�b�h�ł��B
   * @throws OAException -OA��O
   ***************************************************************************
  */
  public void calcBtn() throws OAException
  {
    // �v�Z�������Ăяo��
    calcProcess();
  }

  /***************************************************************************
   * �ꊇ�����������s�����\�b�h�ł��B
   * 
   ***************************************************************************
  */
  public void cancelBtn()
  {
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����擾
    OAViewObject vo = getXxwshStockCanEncQtyVO1();
    OARow row       = null;
    String showActualQuantity = null;
    // 1�s��
    vo.first();
    // �S�����[�v
    while (vo.getCurrentRow() != null )
    {
      // �����Ώۍs���擾
      row = (OARow)vo.getCurrentRow();
      // �������ʂ�0.000���Z�b�g
      row.setAttribute("ShowActualQuantity", "0.000");
      // ���̍s�Ɉړ�
      vo.next();
    }
    // ���������\�����[�W�������擾
    OAViewObject hvo = getXxwshSearchVO1();
    // ���������\�����[�W������1�s�ڂ��擾
    OARow hrow       = (OARow)hvo.first();
    // �������ʍ��v��0.000���Z�b�g
    hrow.setAttribute("SumReservedQuantity", "0.000");
    // �ꊇ�����{�^�������t���O��"1"(������)���Z�b�g
    hrow.setAttribute("PackageLiftFlag", XxwshConstants.PACKAGE_LIFT_FLAG_INCLUDE);
  }

  /***************************************************************************
   * �K�p�{�^���������̏������s�����\�b�h�ł�
   * @throws OAException -OA��O
   ***************************************************************************
   */
  public void applyBtn() throws OAException
  {
    // ���������\�����[�W�������擾
    XxwshSearchVOImpl hvo = getXxwshSearchVO1();
    // ���������\�����[�W�����̈�s�ڂ��擾
    OARow hrow            = (OARow)hvo.first();

    // �g�p���鉺�L���ڂ��N���A���܂��B
    hrow.setAttribute("WarningClass",              null); // �x���敪
    hrow.setAttribute("WarningDate",               null); // �x�����t
    hrow.setAttribute("InstructQtyUpdFlag",        null); // �w�����ʍX�V�t���O
    hrow.setAttribute("Weight",                    null); // �d��
    hrow.setAttribute("Capacity",                  null); // �e��
    hrow.setAttribute("SumWeight",                 null); // �ύڏd�ʍ��v
    hrow.setAttribute("SumCapacity",               null); // �ύڗe�ύ��v
    hrow.setAttribute("LoadingEfficiencyWeight",   null); // �ύڗ��i�d��)
    hrow.setAttribute("LoadingEfficiencyCapacity", null); // �ύڗ�(�e��)
    hrow.setAttribute("SumQuantity",               null); // ���v����
    hrow.setAttribute("SmallQuantity",             null); // ������
    hrow.setAttribute("LabelQuantity",             null); // ���x������
    hrow.setAttribute("PalletWeight",              null); // �p���b�g�d��
    hrow.setAttribute("SumPalletWeight",           null); // ���v�p���b�g�d��

    //�v�Z�������s���܂��B
    calcProcess();

    //�e�[�u���̃��b�N�E�r��������s���܂��B
    getLockAndChkExclusive();

    //�����\����0���傫�����R�[�h�̈����\������ʕ\�����ƕύX���Ȃ����`�F�b�N���܂��B
    chkCanEncQty();
    // ***************************************** //
    // *    �w�����ʍX�V���f                   * //
    // ***************************************** //
    Number lotCtl                  = (Number)hrow.getAttribute("LotCtl");                     // ���b�g�Ǘ�
    Number sumReservedQuantityItem = (Number)hrow.getAttribute("SumReservedQuantityItem");    // �������ʍ��v
    String packageLiftFlag         = (String)hrow.getAttribute("PackageLiftFlag");            // �ꊇ�����{�^�������t���O
    String callPictureKbn          = (String)hrow.getAttribute("CallPictureKbn");             // �ďo��ʋ敪
    String itemClass               = (String)hrow.getAttribute("ItemClass");                  // �i�ڋ敪
    String instructQtyUpdFlag      = null;                                                    // �w�����ʍX�V�t���O

    // ���׏�񃊁[�W�������擾
    OAViewObject lvo               = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                     = (OARow)lvo.first();  
    String instructQty             = (String)lrow.getAttribute("InstructQty");                // �w������

    // �w�����ʂƈ������ʍ��v����v����ꍇ
    if (instructQty.equals(sumReservedQuantityItem.toString()))
    {
      // �w�����ʍX�V�t���O��"0"(�X�V���Ȃ�)���Z�b�g
      instructQtyUpdFlag = XxwshConstants.INSTRUCT_QTY_UPD_FLAG_EXCLUD;
    // �ꊇ�����{�^�������t���O��"1"(������)�ň������ʍ��v��0�̏ꍇ
    } else if (XxwshConstants.PACKAGE_LIFT_FLAG_INCLUDE.equals(packageLiftFlag)
      && (sumReservedQuantityItem.doubleValue() == 0))
    {
      // �w�����ʍX�V�t���O��"0"(�X�V���Ȃ�)���Z�b�g
      instructQtyUpdFlag = XxwshConstants.INSTRUCT_QTY_UPD_FLAG_EXCLUD;
    // ��L�̏����ȊO�̏ꍇ
    } else
    {
      // �w�����ʍX�V�t���O��"1"(�X�V����)���Z�b�g
      instructQtyUpdFlag = XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE;
    }
    // �w�����ʍX�V�t���O�����������\�����[�W�����ɃZ�b�g
    hrow.setAttribute("InstructQtyUpdFlag",instructQtyUpdFlag);

    //�w�����ʍX�V�t���O��"1"(�X�V����j�ꍇ
    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
    {
      // ***************************************** //
      // *    �w�����ʍX�V�`�F�b�N               * //
      // ***************************************** //
      // �ďo��ʋ敪��'1'(�o�׈˗����͉�ʋN���̏ꍇ)
      if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
      {                                  
        // ���b�N����
        XxcmnUtility.rollBack(getOADBTransaction());
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12901);  

      // �ďo��ʋ敪��'3'(�ړ��˗�/�w�����͉�ʋN��)�ŕi�ڋ敪��'5'(���i)�̏ꍇ
      } else if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn)
        && XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
      {
        // ���b�N����
        XxcmnUtility.rollBack(getOADBTransaction());
        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12901);  
      }

      // ***************************************** //
      // *    �z�Ԋ֘A���擾����               * //
      // ***************************************** //
      getDeliveryInfo();
    }

    // �x���`�F�b�N������pageContext���g�p���邽��Co�ōs��
  }
  
  
 /*****************************************************************************
  * ���b�N���擾���A�r���`�F�b�N���s�����\�b�h�ł��B
  * @throws OAException - OA��O
  ****************************************************************************/
  public void getLockAndChkExclusive() throws OAException
  {
    // ���������\�����[�W�������擾
    OAViewObject hvo          = getXxwshSearchVO1();
    // ���������\�����[�W�����̈�s�ڂ��擾
    OARow hrow                = (OARow)hvo.first();

    // ���׏�񃊁[�W�������擾
    OAViewObject lvo          = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                = (OARow)lvo.first();

    Number headerId           = (Number)lrow.getAttribute("HeaderId");         // �w�b�_ID
    Number lineId             = (Number)lrow.getAttribute("LineId");           // ����ID
    String documentTypeCode   = (String)lrow.getAttribute("DocumentTypeCode"); // �����^�C�v
    String headerUpdateDate   = (String)hrow.getAttribute("HeaderUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate     = (String)hrow.getAttribute("LineUpdateDate");   // ���׍X�V����
    String callPictureKbn     = (String)hrow.getAttribute("CallPictureKbn");   // �ďo��ʋ敪
    String exeKbn             = (String)hrow.getAttribute("ExeKbn");           // �N���敪
    String retCode            = null;                                          // �G���[�R�[�h
    String headerUpdateDateDb = null;                                          // �w�b�_�ŏI�X�V��
    String lineUpdateDateDb   = null;                                          // ���׍ŏI�X�V��

    //�ďo��ʋ敪���ړ��̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // ***************************************  //
      // *   �ړ��˗�/�w���w�b�_(�A�h�I��)���b�N    * //
      // *************************************** //
      HashMap movHeaderRet = XxwshUtility.getXxinvMovHeadersLock(
                               getOADBTransaction(),
                               headerId);                                // �w�b�_ID
      retCode              = (String)movHeaderRet.get("retCode");        // �߂�l
      headerUpdateDateDb   = (String)movHeaderRet.get("lastUpdateDate"); // �ŏI�X�V��
      // ���b�N�G���[�̏ꍇ
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ���b�N�G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }

      // ************************************* //
      // *   �ړ��˗�/�w������(�A�h�I��)���b�N   * //
      // ************************************* //
      HashMap movLineRet = XxwshUtility.getXxinvMovLinesLock(
                             getOADBTransaction(),
                             headerId);                              // �w�b�_ID
      retCode            = (String)movLineRet.get("retCode");        // �߂�l
      lineUpdateDateDb   = (String)movLineRet.get("lastUpdateDate"); // �ŏI�X�V��
      // ���b�N�G���[�̏ꍇ
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ���b�N����
        XxcmnUtility.rollBack(getOADBTransaction());
        // ���b�N�G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }
    } else
    {
      // ******************************** //
      // *   �󒍃w�b�_�A�h�I�����b�N   * //
      // ******************************** //
      HashMap orderHeaderRet = XxwshUtility.getXxwshOrderHeadersAllLock(
                                 getOADBTransaction(),
                                 headerId);                                  // �w�b�_ID
      retCode                = (String)orderHeaderRet.get("retFlag");        // �߂�l
      headerUpdateDateDb     = (String)orderHeaderRet.get("lastUpdateDate"); // �ŏI�X�V��

      // ���b�N�G���[�̏ꍇ
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ���b�N�G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }

      // ******************************** //
      // *   �󒍖��׃A�h�I�����b�N   * //
      // ******************************** //
      HashMap orderLineRet = XxwshUtility.getXxwshOrderLinesAllLock(
                               getOADBTransaction(),
                               headerId);                                // �w�b�_ID
      retCode              = (String)orderLineRet.get("retFlag");        // �߂�l
      lineUpdateDateDb     = (String)orderLineRet.get("lastUpdateDate"); // �ŏI�X�V��

      // ���b�N�G���[�̏ꍇ
      if (XxcmnConstants.RETURN_ERR1.equals(retCode))
      {
        // ���b�N����
        XxcmnUtility.rollBack(getOADBTransaction());
        // ���b�N�G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12908);
      }
    }

    // *********************************** //
    // *  �ړ����b�g�ڍ׃A�h�I�����b�N   * //
    // *********************************** //
    retCode = XxwshUtility.getXxinvMovLotDetailsLock(
                getOADBTransaction(),
                lineId,                           // ����ID
                documentTypeCode,                 // �����^�C�v
                XxwshConstants.RECORD_TYPE_DELI); // ���R�[�h�^�C�v
    // ���b�N�G���[�̏ꍇ
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ���b�N����
      XxcmnUtility.rollBack(getOADBTransaction());
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH12908);
    }

    // ******************************** //
    // *  �w�b�_�r���`�F�b�N             * //
    // ******************************** //
    // ���b�N���Ɏ擾�����ŏI�X�V���Ɣ�r
    if (!headerUpdateDateDb.equals(headerUpdateDate))
    {
      //���b�N����
      XxcmnUtility.rollBack(getOADBTransaction());
      // ******************** // 
      // *  �ĕ\��           * //
      // ******************** //  
      HashMap params = new HashMap();
      params.put("LineId", lineId.toString());
      params.put("callPictureKbn",   callPictureKbn);
      params.put("headerUpdateDate", headerUpdateDateDb);
      params.put("lineUpdateDate",   lineUpdateDateDb);
      params.put("exeKbn",           exeKbn);
      initialize(params);
      // �r���G���[���b�Z�[�W�o��

      // �ďo��ʋ敪���ړ��̏ꍇ
      if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
      {
        // �g�[�N������
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_MOV_HEADERS) };
        // �G���[���b�Z�[�W��\��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      // �ďo��ʋ敪���ړ��ȊO�̏ꍇ
      } else
      {
        // �g�[�N������
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_ORDER_HEADERS) };
        // �G���[���b�Z�[�W��\��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      }
    }

    // ******************************** //
    // *   ���הr���`�F�b�N             * //
    // ******************************** //
    // ���b�N���Ɏ擾�����ŏI�X�V���Ɣ�r
    if (!lineUpdateDateDb.equals(lineUpdateDate))
    {
      //���b�N����
      XxcmnUtility.rollBack(getOADBTransaction());
      // ******************** // 
      // *  �ĕ\��           * //
      // ******************** //  
      HashMap params = new HashMap();
      params.put("LineId", lineId.toString());
      params.put("callPictureKbn",   callPictureKbn);
      params.put("headerUpdateDate", headerUpdateDateDb);
      params.put("lineUpdateDate",   lineUpdateDateDb);
      params.put("exeKbn",           exeKbn);
      initialize(params);
      // �r���G���[���b�Z�[�W�o��
      // �ďo��ʋ敪���ړ��̏ꍇ
      if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
      {
        // �g�[�N������
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_MOV_LINES) };
        // �G���[���b�Z�[�W��\��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      // �ďo��ʋ敪���ړ��ȊO�̏ꍇ
      } else
      {
        // �g�[�N������
        MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_TABLE,
                                  XxwshConstants.TABLE_NAME_ORDER_LINES) };
        // �G���[���b�Z�[�W��\��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12907,
          tokens);
      }
    }    
  }

  /***************************************************************************
   * �莝�݌ɐ��E�����\���ꗗ���[�W�����̈����\������ʕ\�����ƕύX���Ȃ����������܂��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkCanEncQty() throws OAException
  {

    // ���������\�����[�W�����擾
    XxwshSearchVOImpl hvo           = getXxwshSearchVO1();
    // ���������\�����[�W������s�ڂ��擾
    OARow hrow                      = (OARow)hvo.first();
    // ���׏�񃊁[�W�������擾
    OAViewObject lvo               = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                     = (OARow)lvo.first();

    // ���������\�����[�W�����A���׏�񃊁[�W�����̍��ڂ��擾
    Number lotCtl                   = (Number)hrow.getAttribute("LotCtl");                     // ���b�g�Ǘ��i
    Number itemId                   = (Number)hrow.getAttribute("ItemId");                     // �i��ID
    Number inputInventoryLocationId = (Number)lrow.getAttribute("InputInventoryLocationId");   // ���͕ۊǑq��ID
    Date scheduleShipDate           = (Date)lrow.getAttribute("ScheduleShipDate");             // �o�ɗ\���
    String inventoryLocationName    = (String)lrow.getAttribute("InputInventoryLocationName"); // �ۊǑq�ɖ�
    String itemCode                 = (String)hrow.getAttribute("ItemCode");                   // �i�ڃR�[�h
    String lineId                   = (String)hrow.getAttribute("LineId");                     // ����ID
    String headerUpdateDate         = (String)hrow.getAttribute("HeaderUpdateDate");           // �w�b�_�X�V����
    String lineUpdateDate           = (String)hrow.getAttribute("LineUpdateDate");             // ���׍X�V����
    String callPictureKbn           = (String)hrow.getAttribute("CallPictureKbn");             // �ďo��ʋ敪
    String exeKbn                   = (String)hrow.getAttribute("ExeKbn");                     // �N���敪
    String convUnitUseKbn           = (String)hrow.getAttribute("ConvUnitUseKbn");             // ���o�Ɋ��Z�P�ʎg�p�敪
    String numOfCases               = (String)hrow.getAttribute("NumOfCases");                 // �P�[�X����

    // �莝�݌ɐ��E�����\���ꗗ���[�W�����擾
    OAViewObject vo                 = getXxwshStockCanEncQtyVO1();
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̃f�[�^�i�[�p�ϐ�
    OARow row                       = null;
    Number canEncQty                = null;                                                    // ��ʕ\���������\��
    Number nowCanEncQty             = null;                                                    // �擾���������\��
    Number lotId                    = null;                                                    // ���b�gID
    Number actualQuantity           = null;                                                    // ��������(���Z��)
    Number actualQuantityBk         = null;                                                    // ��ʕ\������������(���Z��)
    String showLotNo                = null;                                                    // �\���p���b�gNo
    String showCanEncQty            = null;                                                    // ��ʕ\���������\��(���Z��)
    Double setCanEncQty             = null;
    ArrayList exceptions            = new ArrayList(100);                                      // �G���[���b�Z�[�W�i�[�p�z��

    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̈�s�ڂ��Z�b�g
    vo.first();
    // �S�����[�v
    while (vo.getCurrentRow() != null )
    {
      // �����Ώۍs���擾
      row = (OARow)vo.getCurrentRow();

      canEncQty        = (Number)row.getAttribute("CanEncQty");        // ��ʕ\���������\��
      lotId            = (Number)row.getAttribute("LotId");            // ���b�gID
      actualQuantity   = (Number)row.getAttribute("ActualQuantity");   // ��������
      actualQuantityBk = (Number)row.getAttribute("ActualQuantityBk"); // ��ʕ\������������
      showLotNo        = (String)row.getAttribute("ShowLotNo");        // �\���p���b�gNo
      showCanEncQty    = (String)row.getAttribute("ShowCanEncQty");    // ��ʕ\���������\��(���Z��)
      //�������ʂ��ύX����Ă���ꍇ��������0���傫���ꍇ�Ƀ`�F�b�N���s��
      if (!actualQuantityBk.equals(actualQuantity)
        || (actualQuantity.doubleValue() > 0))
      {
        // *********************** // 
        // * �����\���Z�oAPI���s  *//
        // *********************** //
        nowCanEncQty = XxwshUtility.getCanEncQty(
                         getOADBTransaction(),
                         inputInventoryLocationId, // ���͕ۊǑq��ID
                         itemId,                   // �i��ID
                         lotId,                    // ���b�gID
                         lotCtl.toString(),        // ���b�g�Ǘ�
                         scheduleShipDate);        // �L����
        // �擾���������\������ʕ\���������\���ƈ�v���Ȃ��ꍇ
        if (!nowCanEncQty.equals(canEncQty))
        {
          // �g�[�N����錾���Z�b�g
          MessageToken[] tokens = new MessageToken[2];
          
          tokens[0] = new MessageToken(
                            XxwshConstants.TOKEN_LOCATION,
                            inventoryLocationName);
          tokens[1] = new MessageToken(
                            XxwshConstants.TOKEN_LOT,
                            showLotNo);

          // ���Z�Ώۂ̏ꍇ�擾�����������ʂ����Z����
          if (XxwshConstants.CONV_UNIT_USE_KBN_INCLUDE.equals(convUnitUseKbn))
          {
            setCanEncQty = new Double(nowCanEncQty.doubleValue() / Double.parseDouble(numOfCases));
          } else 
          {
            setCanEncQty = new Double(nowCanEncQty.doubleValue());
          }
          // �G���[���b�Z�[�W��ǉ�
          exceptions.add( 
            new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                vo.getName(),
                row.getKey(),
                "ShowCanEncQty",
                XxcmnUtility.formConvNumber(setCanEncQty, 9, 3, true),
                XxcmnConstants.APPL_XXWSH,         
                XxwshConstants.XXWSH12906,
                tokens));
        }
      }
      // ���̃��R�[�h��
      vo.next();
    }
    //�G���[������ꍇ���b�Z�[�W���o��
    if(exceptions.size() > 0)
    {
      // ���b�N����
      XxcmnUtility.rollBack(getOADBTransaction());
      // ******************** // 
      // *  �ĕ\��           * //
      // ******************** // 
      HashMap params = new HashMap();
      params.put("LineId",           lineId);
      params.put("callPictureKbn",   callPictureKbn);
      params.put("headerUpdateDate", headerUpdateDate);
      params.put("lineUpdateDate",   lineUpdateDate);
      params.put("exeKbn",           exeKbn);
      initialize(params);
      // �G���[���b�Z�[�W���o��
      OAException.raiseBundledOAException(exceptions);
    }

  }

  /***************************************************************************
   * ���ׂƃw�b�_�̔z�Ԋ֘A�����Z�o���܂��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getDeliveryInfo() throws OAException
  {

    // ���������\�����[�W�����擾
    OAViewObject hvo                 = getXxwshSearchVO1();
    // ���������\�����[�W������s�ڂ��擾
    OARow hrow                       = (OARow)hvo.first();

    // ���������\�����[�W�����̍��ڂ��擾
    String itemCode                  = (String)hrow.getAttribute("ItemCode");                // �i�ڃR�[�h
// 2008-12-10 H.Itou Mod Start
//    Number sumReservedQuantityItem   = (Number)hrow.getAttribute("SumReservedQuantityItem"); // �������ʍ��v(�i�ڒP��)
    BigDecimal sumReservedQuantityItem = XxcmnUtility.bigDecimalValue(XxcmnUtility.stringValue((Number)hrow.getAttribute("SumReservedQuantityItem"))); // �������ʍ��v(�i�ڒP��)
// 2008-12-10 H.Itou Mod End
    String callPictureKbn            = (String)hrow.getAttribute("CallPictureKbn");          // �ďo��ʋ敪
    String numOfCases                = (String)hrow.getAttribute("NumOfCases");              // �P�[�X����
    String numOfDeliver              = (String)hrow.getAttribute("NumOfDeliver");            // �o�ד���

    // ���׏�񃊁[�W�������擾
    OAViewObject lvo                 = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                       = (OARow)lvo.first();  

    // ���׏�񃊁[�W�����̍��ڂ��擾
    Number headerId                   = (Number)lrow.getAttribute("HeaderId");                   // �w�b�_ID
    Number lineId                     = (Number)lrow.getAttribute("LineId");                     // ����ID
    Date scheduleShipDate             = (Date)lrow.getAttribute("ScheduleShipDate");             // �o�ɗ\���
    String headerProdClass            = (String)lrow.getAttribute("HeaderProdClass");            // ���i�敪
    String weightCapacityClass        = (String)lrow.getAttribute("WeightCapacityClass");        // �d�ʗe�ϋ敪
    String deliverTo                  = (String)lrow.getAttribute("DeliverTo");                  // �o�ɐ�
    String inputInventoryLocationCode = (String)lrow.getAttribute("InputInventoryLocationCode"); // �o�Ɍ�
    String freightChargeClass         = (String)lrow.getAttribute("FreightChargeClass");         // �^���敪

    // �z�Ԋ֘A�����i�[����ϐ���錾
// 2008-12-10 H.Itou Mod Start
//    double weight                    = 0;     // �d��
//    double capacity                  = 0;     // �e��
//    double sumWeight                 = 0;     // �ύڏd�ʍ��v
//    double sumCapacity               = 0;     // �ύڗe�ύ��v
//    double loadingEfficiencyWeight   = 0;     // �ύڌ���(�d��)
//    double loadingEfficiencyCapacity = 0;     // �ύڌ���(�e��)
//    double sumQuantity               = 0;     // ���v����
//    double smallQuantity             = 0;     // ������
//    double labelQuantity             = 0;     // ���x������
//    double palletWeight              = 0;     // �p���b�g�d��
//    double sumPalletWeight           = 0;     // ���v�p���b�g�d��
//
    BigDecimal weight                    = new BigDecimal(0);     // �d��
    BigDecimal capacity                  = new BigDecimal(0);     // �e��
    BigDecimal sumWeight                 = new BigDecimal(0);     // �ύڏd�ʍ��v
    BigDecimal sumCapacity               = new BigDecimal(0);     // �ύڗe�ύ��v
    BigDecimal loadingEfficiencyWeight   = new BigDecimal(0);     // �ύڌ���(�d��)
    BigDecimal loadingEfficiencyCapacity = new BigDecimal(0);     // �ύڌ���(�e��)
    BigDecimal sumQuantity               = new BigDecimal(0);     // ���v����
    BigDecimal smallQuantity             = new BigDecimal(0);     // ������
    BigDecimal labelQuantity             = new BigDecimal(0);     // ���x������
    BigDecimal palletWeight              = new BigDecimal(0);     // �p���b�g�d��
    BigDecimal sumPalletWeight           = new BigDecimal(0);     // ���v�p���b�g�d��
// 2008-12-10 H.Itou Mod End
    String retCode                    = null; // ���^�[���R�[�h
    String errMsg                     = null; // �G���[���b�Z�[�W
    String systemMsg                  = null; // �V�X�e���G���[���b�Z�[�W
    String loadingOverClass           = null; // �ύڃI�[�o�[�敪
    String shipMethod                 = null; // �z���敪
    String loadEfficiencyWeight       = null; // �d�ʐύڌ���
    String loadEfficiencyCapacity     = null; // �e�ϐύڌ���
    String mixedShipMethod            = null; // ���ڔz���敪
    String smallAmountClass           = null; // �����敪
    // ******************************************* // 
    // *  ��ʂőΏۂƂȂ��Ă��閾�ׂ̏d�ʂƗe�ς��擾 * //
    // ******************************************* // 
    HashMap paramsRet = XxwshUtility.calcTotalValue(
                          getOADBTransaction(),
                          itemCode,
                          sumReservedQuantityItem.toString(),
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
                          scheduleShipDate
// 2008-10-07 H.Itou Add End
                          );
    // �擾�����d�ʂ�NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull((String)paramsRet.get("sumWeight")))
    {
// 2008-12-10 H.Itou Mod Start
//      // �d�ʂ��Z�b�g
//      weight                 = Double.parseDouble((String)paramsRet.get("sumWeight"));
//      // ���������\�����[�W�����ɃZ�b�g���邽�ߌ^�ϊ�
//      BigDecimal setWeigtht  = new BigDecimal(String.valueOf(weight));
//      // ���ׂ̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
//      hrow.setAttribute("Weight", XxcmnUtility.stringValue(setWeigtht));
//      // �w�b�_�ɃZ�b�g���鍇�v�d�ʂɉ��Z
//      sumWeight              = sumWeight + weight;
      // �d�ʂ��Z�b�g
      weight = XxcmnUtility.bigDecimalValue((String)paramsRet.get("sumWeight"));
      // ���ׂ̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
      hrow.setAttribute("Weight", (String)paramsRet.get("sumWeight"));
      // �w�b�_�ɃZ�b�g���鍇�v�d�ʂɉ��Z
      sumWeight = sumWeight.add(weight);
// 2008-12-10 H.Itou Mod End
    }

    // �擾�����e�ς�NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull((String)paramsRet.get("sumCapacity")))
    {
// 2008-12-10 H.Itou Mod Start
//      // �e�ς��Z�b�g
//      capacity                = Double.parseDouble((String)paramsRet.get("sumCapacity"));
//      // ���������\�����[�W�����ɃZ�b�g���邽�ߌ^�ϊ�
//      BigDecimal setCapacity  = new BigDecimal(String.valueOf(capacity));
//      // ���ׂ̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
//      hrow.setAttribute("Capacity",XxcmnUtility.stringValue(setCapacity));
//      // �w�b�_�ɃZ�b�g���鍇�v�e�ςɉ��Z
//      sumCapacity             = sumCapacity + capacity;
      // �e�ς��Z�b�g
      capacity = XxcmnUtility.bigDecimalValue((String)paramsRet.get("sumCapacity"));
      // ���ׂ̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
      hrow.setAttribute("Capacity", (String)paramsRet.get("sumCapacity"));
      // �w�b�_�ɃZ�b�g���鍇�v�e�ςɉ��Z
      sumCapacity = sumCapacity.add(capacity);
// 2008-12-10 H.Itou Mod End
    }

    // �擾�����p���b�g�d�ʂ�NULL�ȊO�Ōďo��ʋ敪���x���w���쐬��ʋN���ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull((String)paramsRet.get("sumPalletWeigh"))
      && !XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
    {
// 2008-12-10 H.Itou Mod Start
//      // �p���b�g�d�ʂ��Z�b�g
//      palletWeight                = Double.parseDouble((String)paramsRet.get("sumPalletWeigh"));
//      // ���������\�����[�W�����ɃZ�b�g���邽�ߌ^�ϊ�
//      BigDecimal setPalletWeight  = new BigDecimal(String.valueOf(palletWeight));
//      // ���ׂ̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
//      hrow.setAttribute("PalletWeight",XxcmnUtility.stringValue(setPalletWeight));
//      // �w�b�_�ɃZ�b�g���鍇�v�p���b�g�d�ʂɉ��Z
//      sumPalletWeight             = sumPalletWeight + palletWeight;
      // �p���b�g�d�ʂ��Z�b�g
      palletWeight = XxcmnUtility.bigDecimalValue((String)paramsRet.get("sumPalletWeigh"));
      // ���ׂ̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
      hrow.setAttribute("PalletWeight", (String)paramsRet.get("sumPalletWeigh"));
      // �w�b�_�ɃZ�b�g���鍇�v�p���b�g�d�ʂɉ��Z
      sumPalletWeight = sumPalletWeight.add(palletWeight);
// 2008-12-10 H.Itou Mod End
    }
    // ���v���ʂɖ��ׂ̐��ʂ����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//    sumQuantity = sumQuantity + sumReservedQuantityItem.doubleValue();
    sumQuantity = sumQuantity.add(sumReservedQuantityItem);
// 2008-12-10 H.Itou Mod End
    if (sumReservedQuantityItem.doubleValue() == 0 )
    {
      // �������s���܂���B

    // �o�ד������ݒ肳��Ă���ꍇ
    } else if (!XxcmnUtility.isBlankOrNull(numOfDeliver))
    {
      // �������Ɉ������ʍ��v���o�ד����Ŋ������l�����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      smallQuantity = smallQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver)));
//      smallQuantity = smallQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver));
//// 2008/08/07 D.Nihei Mod End
      smallQuantity = smallQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfDeliver), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
      // ���x�������Ɉ������ʍ��v���o�ד����Ŋ������l�����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      labelQuantity = labelQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver)));
//      labelQuantity = labelQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfDeliver));
//// 2008/08/07 D.Nihei Mod End
      labelQuantity = labelQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfDeliver), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End

    // �P�[�X�������ݒ肳��Ă���ꍇ
    } else if (!XxcmnUtility.isBlankOrNull(numOfCases))
    {
      // �������Ɉ������ʍ��v���P�[�X�����Ŋ������l�����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      smallQuantity = smallQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases)));
//      smallQuantity = smallQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases));
//// 2008/08/07 D.Nihei Mod End
      smallQuantity = smallQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfCases), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
      // ���x�������Ɉ������ʍ��v���P�[�X�����Ŋ������l�����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      labelQuantity = labelQuantity + Math.round((sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases)));
//      labelQuantity = labelQuantity + Math.ceil(sumReservedQuantityItem.doubleValue() / Double.parseDouble(numOfCases));
//// 2008/08/07 D.Nihei Mod End
      labelQuantity = labelQuantity.add(sumReservedQuantityItem.divide(XxcmnUtility.bigDecimalValue(numOfCases), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    // ��L�ȊO�̏ꍇ
    } else
    {
      // �������Ɉ������ʍ��v�����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      smallQuantity = smallQuantity + sumReservedQuantityItem.doubleValue();
//      smallQuantity = smallQuantity + Math.ceil(sumReservedQuantityItem.doubleValue());
//// 2008/08/07 D.Nihei Mod End
      smallQuantity = smallQuantity.add(sumReservedQuantityItem.divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod Start
      // ���x�������Ɉ������ʍ��v�����Z���܂��B
// 2008-12-10 H.Itou Mod Start
//// 2008/08/07 D.Nihei Mod Start
////      labelQuantity = labelQuantity + sumReservedQuantityItem.doubleValue();
//      labelQuantity = labelQuantity + Math.ceil(sumReservedQuantityItem.doubleValue());
//// 2008/08/07 D.Nihei Mod End
      labelQuantity = labelQuantity.add(sumReservedQuantityItem.divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    }

    // ********************************************************** //
    // *  ��ʂőΏۂƂȂ��Ă��閾�ׂƓ����w�b�_�̐��ʁA�d�ʁA�e�ς��擾 * //
    // ********************************************************** //
    HashMap lineParams = null;
    // �ďo��ʋ敪���ړ��˗�/�w�����͉�ʋN���̏ꍇ
    if(XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      lineParams = XxwshUtility.getDeliverSummaryMoveLine(
                     getOADBTransaction(),
                     headerId,
                     lineId,
                     scheduleShipDate);
    // �ďo��ʋ敪���ړ��˗�/�w�����͉�ʋN���ȊO�̏ꍇ
    } else
    {
      lineParams = XxwshUtility.getDeliverSummaryOrderLine(
                     getOADBTransaction(),
                     headerId,
                     lineId,
                     scheduleShipDate);
    }
    String returnSumQty             = (String)lineParams.get("sumQuantity");       // ����
    String returnSumWeight          = (String)lineParams.get("sumWeight");         // �d��
    String returnSumCapacity        = (String)lineParams.get("sumCapacity");       // �e��
    String returnSumPalletWeight    = (String)lineParams.get("sumPalletWeight");   // �p���b�g�d��
    String returnSumSmallQuantity   = (String)lineParams.get("sumSmallQuantity");  // ������
    String returnSumLabelQuantity   = (String)lineParams.get("sumLabelQuantity");  // ���x������

    // �擾�������ʂ�NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull(returnSumQty))
    {
      // �擾�������ʂ����v���ʂɉ��Z
// 2008-12-10 H.Itou Mod Start
//      sumQuantity      = sumQuantity + Double.parseDouble(returnSumQty);
      sumQuantity      = sumQuantity.add(XxcmnUtility.bigDecimalValue(returnSumQty));
// 2008-12-10 H.Itou Mod End
    }
    // �擾�����d�ʂ�NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull(returnSumWeight))
    {
      // �擾�����d�ʂ����v�d�ʂɉ��Z
// 2008-12-10 H.Itou Mod Start
//      sumWeight        = sumWeight + Double.parseDouble(returnSumWeight);
      sumWeight        = sumWeight.add(XxcmnUtility.bigDecimalValue(returnSumWeight));
// 2008-12-10 H.Itou Mod End
    }
    // �擾�����e�ς�NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull(returnSumCapacity))
    {
      // �擾�����e�ς����v�e�ςɉ��Z
// 2008-12-10 H.Itou Mod Start
//      sumCapacity      = sumCapacity + Double.parseDouble(returnSumCapacity);
      sumCapacity        = sumCapacity.add(XxcmnUtility.bigDecimalValue(returnSumCapacity));
// 2008-12-10 H.Itou Mod End
    }
    // �擾�����p���b�g�d�ʂ�NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull(returnSumPalletWeight))
    {
      // �擾�����p���b�g�d�ʂ����v�p���b�g�d�ʂɉ��Z
// 2008-12-10 H.Itou Mod Start
//      sumPalletWeight  = sumPalletWeight + Double.parseDouble(returnSumPalletWeight);
      sumPalletWeight  = sumPalletWeight.add(XxcmnUtility.bigDecimalValue(returnSumPalletWeight));
// 2008-12-10 H.Itou Mod End
    }
    // �擾������������NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull(returnSumSmallQuantity))
    {
// 2008-12-10 H.Itou Mod Start
      // �擾�������������������ɉ��Z
//      smallQuantity    = smallQuantity + Double.parseDouble(returnSumSmallQuantity);
      smallQuantity    = smallQuantity.add(XxcmnUtility.bigDecimalValue(returnSumSmallQuantity).divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    }
    // �擾�������x��������NULL�ȊO�̏ꍇ
    if (!XxcmnUtility.isBlankOrNull(returnSumLabelQuantity))
    {
      // �擾�������x�����������x�������ɉ��Z
// 2008-12-10 H.Itou Mod Start
//      labelQuantity    = labelQuantity + Double.parseDouble(returnSumLabelQuantity);
      labelQuantity    = labelQuantity.add(XxcmnUtility.bigDecimalValue(returnSumLabelQuantity).divide(new BigDecimal(1), 0, BigDecimal.ROUND_CEILING));
// 2008-12-10 H.Itou Mod End
    }

    // ���������\�����[�W�����ɃZ�b�g���邽�߈ꎞ�I�Ɍ^�ϊ�
// 2008-12-10 H.Itou Mod Start
//    BigDecimal setSumQuantity     = new BigDecimal(String.valueOf(sumQuantity));      // ���v����
//    BigDecimal setSumWeight       = new BigDecimal(String.valueOf(sumWeight));        // ���v�d��
//    BigDecimal setSumCapacity     = new BigDecimal(String.valueOf(sumCapacity));      // ���v�e��
//    BigDecimal setSumPalletWeight = new BigDecimal(String.valueOf(sumPalletWeight));  // ���v�p���b�g�d��
//    BigDecimal setSmallQuantity   = new BigDecimal(String.valueOf(smallQuantity));    // ������
//    BigDecimal setLabelQuantity   = new BigDecimal(String.valueOf(labelQuantity));    // ���x������
    BigDecimal setSumQuantity     = sumQuantity;      // ���v����
    BigDecimal setSumWeight       = sumWeight;        // ���v�d��
    BigDecimal setSumCapacity     = sumCapacity;      // ���v�e��
    BigDecimal setSumPalletWeight = sumPalletWeight;  // ���v�p���b�g�d��
    BigDecimal setSmallQuantity   = smallQuantity;    // ������
    BigDecimal setLabelQuantity   = labelQuantity;    // ���x������
// 2008-12-10 H.Itou Mod End

    // �w�b�_�̍X�V�Ɏg�p���邽�ߌ��������\�����[�W�����ɃZ�b�g
    hrow.setAttribute("SumQuantity"    ,XxcmnUtility.stringValue(setSumQuantity));     // ���v����
    hrow.setAttribute("SumWeight"      ,XxcmnUtility.stringValue(setSumWeight));       // ���v�d��
    hrow.setAttribute("SumCapacity"    ,XxcmnUtility.stringValue(setSumCapacity));     // ���v�e��
    hrow.setAttribute("SumPalletWeight",XxcmnUtility.stringValue(setSumPalletWeight)); // ���v�p���b�g�d��
    hrow.setAttribute("SmallQuantity"  ,XxcmnUtility.stringValue(setSmallQuantity));   // ������
    hrow.setAttribute("LabelQuantity"  ,XxcmnUtility.stringValue(setLabelQuantity));   // ���x������

    // �^���敪���g�p����ꍇ
    if (XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(freightChargeClass))
    {
      // ***************************** //
      // *  �ő�z���敪���Z�o         * //
      // ***************************** //
      // �ő�z���敪�Ɏg�p����ϐ���錾
      String codeClass1 = XxwshConstants.CODE_KBN_4; // �R�[�h�N���X1
      String codeClass2 = null;                      // �R�[�h�N���X2

      // �o�׈˗����͉�ʋN���̏ꍇ
      if(XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
      {
        codeClass2 = XxwshConstants.CODE_KBN_9; // �R�[�h�N���X2

      // �x���w���쐬��ʋN���̏ꍇ    
      } else if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
      {
        codeClass2 = XxwshConstants.CODE_KBN_11; // �R�[�h�N���X2

      // �ړ��˗�/�w�����͉�ʋN���̏ꍇ
      } else if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
      {
        codeClass2 = XxwshConstants.CODE_KBN_4; // �R�[�h�N���X2
      }
    
      // �ő�z���敪���擾
      HashMap shipParams = XxwshUtility.getMaxShipMethod(
                             getOADBTransaction(),
                             codeClass1,                 // �R�[�h�敪1
                             inputInventoryLocationCode, // �o�Ɍ�
                             codeClass2,                 // �R�[�h�敪2
                             deliverTo,                  // �o�ɐ�
                             weightCapacityClass,        // �d�ʗe�ϋ敪
                             headerProdClass,            // �w�b�_���i�敪
                             null,                       // �����z�ԑΏۋ敪
                             scheduleShipDate);          // �o�ɗ\���
      String maxShipMethods  = (String)shipParams.get("maxShipMethods");  // �ő�z���敪
      String paletteMaxQty   = (String)shipParams.get("paletteMaxQty");   // �p���b�g�ő喇��
      String deadWeight      = (String)shipParams.get("deadWeight");      // �ύڏd��
      String loadingCapacity = (String)shipParams.get("loadingCapacity"); // �ύڗe��

      // �ő�z���敪��NULL�̏ꍇ
      if (XxcmnUtility.isBlankOrNull(maxShipMethods))
      {
        // ���b�N����
        XxcmnUtility.rollBack(getOADBTransaction());
        // �g�[�N�����쐬
        MessageToken[] tokens = new MessageToken[6];
        tokens[0] = new MessageToken(
                      XxwshConstants.TOKEN_CODE_KBN1,
                      codeClass1);
        tokens[1] = new MessageToken(
                      XxwshConstants.TOKEN_SHIP_FROM,
                      inputInventoryLocationCode);
        tokens[2] = new MessageToken(
                      XxwshConstants.TOKEN_CODE_KBN2,
                      codeClass2);
        tokens[3] = new MessageToken(
                      XxwshConstants.TOKEN_SHIP_TO,
                      deliverTo);
        tokens[4] = new MessageToken(
                      XxwshConstants.TOKEN_PROD_CLASS,
                      headerProdClass);
        tokens[5] = new MessageToken(
                      XxwshConstants.TOKEN_SHIP_DATE,
                      XxcmnUtility.stringValue(scheduleShipDate));
                                     
        // �G���[���b�Z�[�W��\��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12910,
          tokens);
      }
      // �ő�z���敪�̏����敪�擾
      smallAmountClass = XxwshUtility.getSmallKbn(
                           getOADBTransaction(),
                           maxShipMethods,
                           scheduleShipDate);      
      // ******************************* //
      // *  �ő�z���敪�ł̐ύڌ����`�F�b�N* //
      // ******************************* //
      // �d�ʗe�ϋ敪���d�ʂ̏ꍇ
      if (XxwshConstants.WGHT_CAPA_CLASS_WEIGHT.equals(weightCapacityClass))
      {
        // �ďo��ʋ敪���x���̏ꍇ
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
// 2008-12-10 H.Itou Mod Start
//          setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // ���v�d��
          setSumWeight = sumWeight; // ���v�d��
// 2008-12-10 H.Itou Mod End

        // �����敪���Ώۂ̏ꍇ
        } else if (XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(smallAmountClass))
        {
// 2008-12-10 H.Itou Mod Start
//          setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // ���v�d��
          setSumWeight = sumWeight; // ���v�d��
// 2008-12-10 H.Itou Mod End

        } else
        {
// 2008-12-10 H.Itou Mod Start
//          setSumWeight = new BigDecimal(String.valueOf(sumWeight + sumPalletWeight)); // ���v�d�� + �p���b�g�d��    
          setSumWeight = sumWeight.add(sumPalletWeight); // ���v�d�� + �p���b�g�d��    
// 2008-12-10 H.Itou Mod End
        }

        setSumCapacity = null; // ���v�e�ς�NULL���Z�b�g
      // �d�ʗe�ϋ敪���e�ς̏ꍇ      
      } else if (XxwshConstants.WGHT_CAPA_CLASS_CAPACITY.equals(weightCapacityClass))
      {
// 2008-12-10 H.Itou Mod Start
//        setSumCapacity = new BigDecimal(String.valueOf(sumCapacity)); // ���v�e��
        setSumCapacity = sumCapacity; // ���v�e��
// 2008-12-10 H.Itou Mod End
        setSumWeight = null; // ���v
      }
      // �ő�ύڌ����`�F�b�N
      HashMap maxParams = XxwshUtility.calcLoadEfficiency(
                            getOADBTransaction(),
                            XxcmnUtility.stringValue(setSumWeight),
                            XxcmnUtility.stringValue(setSumCapacity),
                            codeClass1,
                            inputInventoryLocationCode,
                            codeClass2,
                            deliverTo,
                            maxShipMethods,
                            scheduleShipDate,
                            headerProdClass);
      // �߂�l���擾
      retCode                = (String)maxParams.get("retCode");                // ���^�[���R�[�h
      errMsg                 = (String)maxParams.get("retCode");                // �G���[���b�Z�[�W
      systemMsg              = (String)maxParams.get("systemMsg");              // �V�X�e���G���[���b�Z�[�W
      loadingOverClass       = (String)maxParams.get("loadingOverClass");       // �V�X�e���G���[���b�Z�[�W
      shipMethod             = (String)maxParams.get("shipMethod");             // �z���敪
      loadEfficiencyWeight   = (String)maxParams.get("loadEfficiencyWeight");   // �d�ʐύڌ���
      loadEfficiencyCapacity = (String)maxParams.get("loadEfficiencyCapacity"); // �e�ϐύڌ���
      mixedShipMethod        = (String)maxParams.get("mixedShipMethod");        // ���ڔz���敪
      
      // �ύڃI�[�o�̏ꍇ
      if (XxwshConstants.LOADING_OVER_CLASS_OVER.equals(loadingOverClass))
      {
        String kubunName         = null; // �敪����
        String loadingEfficiency = null; // �ύڌ���
        // �d�ʗe�ϋ敪���d�ʂ̏ꍇ
        if (XxwshConstants.WGHT_CAPA_CLASS_WEIGHT.equals(weightCapacityClass))
        {
          kubunName         = XxwshConstants.TOKEN_NAME_WEIGHT; // �d��
          loadingEfficiency = loadEfficiencyWeight;             // �d�ʐύڌ���
        } else if (XxwshConstants.WGHT_CAPA_CLASS_CAPACITY.equals(weightCapacityClass))
        {
          kubunName         = XxwshConstants.TOKEN_NAME_CAPACITY; // �e��
          loadingEfficiency = loadEfficiencyCapacity;             // �e�ϐύڌ���
        }
        // ���b�N����
        XxcmnUtility.rollBack(getOADBTransaction());
        // �g�[�N�����쐬
        MessageToken[] tokens = new MessageToken[2];
        tokens[0] = new MessageToken(
                      XxwshConstants.TOKEN_KUBUN,
                      kubunName);
        tokens[1] = new MessageToken(
                      XxwshConstants.TOKEN_LOADING_EFFICIENCY,
                      loadingEfficiency);
                                     
        // �G���[���b�Z�[�W��\��
        throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH12909,
          tokens);

      }

      // ************************************* //
      // *  �w�b�_�ɃZ�b�g���邽�߂̐ύڌ������Z�o* //
      // ************************************* //

      // �w�b�_�̏����敪�A�z���敪���擾
      String shipMethodMeaning = (String)lrow.getAttribute("ShipMethodMeaning"); // �z���敪
      smallAmountClass         = (String)lrow.getAttribute("SmallAmountClass");  // �����敪
// 2008/08/07 D.Nihei Del Start
//      // ���v�d�ʂ�0���傫���ꍇ
//      if (sumWeight > 0 )
//      {
// 2008/08/07 D.Nihei Del End
      // �ďo��ʋ敪���x���̏ꍇ
      if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
      {
// 2008-12-10 H.Itou Mod Start
//        setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // ���v�d��
        setSumWeight = sumWeight; // ���v�d��
// 2008-12-10 H.Itou Mod End

      // �����敪���Ώۂ̏ꍇ
      } else if (XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(smallAmountClass))
      {
// 2008-12-10 H.Itou Mod Start
//        setSumWeight = new BigDecimal(String.valueOf(sumWeight)); // ���v�d��
        setSumWeight = sumWeight; // ���v�d��
// 2008-12-10 H.Itou Mod End
      } else
      {
// 2008-12-10 H.Itou Mod Start
//        setSumWeight = new BigDecimal(String.valueOf(sumWeight + sumPalletWeight)); // ���v�d�� + �p���b�g�d��    
        setSumWeight = sumWeight.add(sumPalletWeight); // ���v�d�� + �p���b�g�d��    
// 2008-12-10 H.Itou Mod End 
      }

      setSumCapacity = null; // ���v�e�ς�NULL���Z�b�g
      // �ő�ύڌ����`�F�b�N
      HashMap weightParams = XxwshUtility.calcLoadEfficiency(
                               getOADBTransaction(),
                               XxcmnUtility.stringValue(setSumWeight),
                               XxcmnUtility.stringValue(setSumCapacity),
                               codeClass1,
                               inputInventoryLocationCode,
                               codeClass2,
                               deliverTo,
                               shipMethodMeaning,
                               scheduleShipDate,
                               headerProdClass);
      // �߂�l���擾
      retCode                = (String)weightParams.get("retCode");                // ���^�[���R�[�h
      errMsg                 = (String)weightParams.get("retCode");                // �G���[���b�Z�[�W
      systemMsg              = (String)weightParams.get("systemMsg");              // �V�X�e���G���[���b�Z�[�W
      loadingOverClass       = (String)weightParams.get("loadingOverClass");       // �V�X�e���G���[���b�Z�[�W
      shipMethod             = (String)weightParams.get("shipMethod");             // �z���敪
      loadEfficiencyWeight   = (String)weightParams.get("loadEfficiencyWeight");   // �d�ʐύڌ���
      loadEfficiencyCapacity = (String)weightParams.get("loadEfficiencyCapacity"); // �e�ϐύڌ���
      mixedShipMethod        = (String)weightParams.get("mixedShipMethod");        // ���ڔz���敪

      // �擾�����d�ʐύڌ��������������\�����[�W�����ɃZ�b�g
      hrow.setAttribute("LoadingEfficiencyWeight" ,loadEfficiencyWeight.toString());
        
// 2008/08/07 D.Nihei Del Start
//      }
//      // ���v�e�ς�0���傫���ꍇ
//      if (sumCapacity > 0)
//      {
// 2008/08/07 D.Nihei Del End
// 2008-12-10 H.Itou Mod Start
//      setSumCapacity = new BigDecimal(String.valueOf(sumCapacity)); // ���v�e��
      setSumCapacity = sumCapacity; // ���v�e��
// 2008-12-10 H.Itou Mod End
      setSumWeight = null; // �d�ʍ��v
      // �ő�ύڌ����`�F�b�N
      HashMap capParams = XxwshUtility.calcLoadEfficiency(
                            getOADBTransaction(),
                            XxcmnUtility.stringValue(setSumWeight),
                            XxcmnUtility.stringValue(setSumCapacity),
                            codeClass1,
                            inputInventoryLocationCode,
                            codeClass2,
                            deliverTo,
                            shipMethodMeaning,
                            scheduleShipDate,
                            headerProdClass);
      // �߂�l���擾
      retCode                = (String)capParams.get("retCode");                // ���^�[���R�[�h
      errMsg                 = (String)capParams.get("retCode");                // �G���[���b�Z�[�W
      systemMsg              = (String)capParams.get("systemMsg");              // �V�X�e���G���[���b�Z�[�W
      loadingOverClass       = (String)capParams.get("loadingOverClass");       // �V�X�e���G���[���b�Z�[�W
      shipMethod             = (String)capParams.get("shipMethod");             // �z���敪
      loadEfficiencyWeight   = (String)capParams.get("loadEfficiencyWeight");   // �d�ʐύڌ���
      loadEfficiencyCapacity = (String)capParams.get("loadEfficiencyCapacity"); // �e�ϐύڌ���
      mixedShipMethod        = (String)capParams.get("mixedShipMethod");        // ���ڔz���敪

      // �擾�����e�ϐύڌ��������������\�����[�W�����ɃZ�b�g
      hrow.setAttribute("LoadingEfficiencyCapacity" ,loadEfficiencyCapacity.toString());
// 2008/08/07 D.Nihei Del Start
//      }
// 2008/08/07 D.Nihei Del End
    }
  }

  /***************************************************************************
   * �x���`�F�b�N���s�����\�b�h�ł��B
   * @return HashMap     - �x���G���[���
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap checkWarning() throws OAException
  {
    HashMap msg = new HashMap();
    // ���������\�����[�W�����擾
    OAViewObject hvo                 = getXxwshSearchVO1();
    // ���������\�����[�W������s�ڂ��擾
    OARow hrow                       = (OARow)hvo.first();

    // ���������\�����[�W�����̍��ڂ��擾
    String itemCode                  = (String)hrow.getAttribute("ItemCode");                // �i�ڃR�[�h
    String callPictureKbn            = (String)hrow.getAttribute("CallPictureKbn");          // �ďo��ʋ敪
    Number lotCtl                    = (Number)hrow.getAttribute("LotCtl");                  // ���b�g�Ǘ�    
    String prodClass                 = (String)hrow.getAttribute("ProdClass");               // ���i�敪
    String itemClass                 = (String)hrow.getAttribute("ItemClass");               // �i�ڋ敪
    Number itemId                    = (Number)hrow.getAttribute("ItemId");                  // �i��ID
    String itemShortName             = (String)hrow.getAttribute("ItemShortName");           // �i�ڗ���
// 2009-01-22 H.Itou ADD START �{��#1000�Ή�
    String requestNo                 = (String)hrow.getAttribute("RequestNo");                // �˗�No
// 2009-01-22 H.Itou ADD END
    // ���������\�����[�W�����i�[�p�ϐ�
    String warningClass              = null;                                                 // �x���敪
    Date   warningDate               = null;                                                 // �x�����t

    // ���׏�񃊁[�W�������擾
    OAViewObject lvo                 = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                       = (OARow)lvo.first();

    // ���׏�񃊁[�W�����̍��ڂ��擾
    Number deliverToId               = (Number)lrow.getAttribute("DeliverToId");                // �o�ɐ�ID
    String deliverTo                 = (String)lrow.getAttribute("DeliverTo");                  // �o�ɐ�(�R�[�h)
    Date scheduleArrivalDate         = (Date)lrow.getAttribute("ScheduleArrivalDate");          // ���ɗ\���
    Date scheduleShipDate            = (Date)lrow.getAttribute("ScheduleShipDate");             // �o�ɗ\���
    Number inventoryLocationId       = (Number)lrow.getAttribute("InputInventoryLocationId");   // �ۊǑq��ID
    String locationName              = (String)lrow.getAttribute("InputInventoryLocationName"); // �o�Ɍ��ۊǏꏊ
// 2008-10-22 D.Nihei ADD START �����e�X�g�w�E194�Ή�
    String deliverToName             = (String)lrow.getAttribute("DeliverToName");              // ���ɐ�ۊǏꏊ
// 2008-10-22 D.Nihei ADD END

   // �莝�݌ɐ��E�����\���ꗗ���[�W�����擾
    OAViewObject vo                  = getXxwshStockCanEncQtyVO1();
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̃f�[�^�i�[�p�ϐ�
    OARow row                        = null;
    double canEncQty                 = 0;                                                    // ��ʕ\���������\��
// 2008-12-10 H.Itou Add Start
    BigDecimal canEncQtyBigD         = new BigDecimal(0);                                   // ��ʕ\���������\��
// 2008-12-10 H.Itou Add End
    Number lotId                     = null;                                                 // ���b�gID
    double actualQuantity            = 0;                                                    // ��������(���Z��)
    double actualQuantityBk          = 0;                                                    // ��ʕ\������������(���Z��)
// 2008-12-10 H.Itou Add Start
    BigDecimal actualQuantityBigD        = new BigDecimal(0);                                   // ��������(���Z��)
    BigDecimal actualQuantityBkBigD      = new BigDecimal(0);                                   // ��ʕ\������������(���Z��)
// 2008-12-10 H.Itou Add End
    String showLotNo                 = null;                                                 // �\���p���b�gNo
    String productionDate            = null;                                                 // �����N����

    // �x�����i�[�p
    String[]  lotRevErrFlgRow   = new String[vo.getRowCount()]; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    String[]  freshErrFlgRow    = new String[vo.getRowCount()]; // �N�x�����`�F�b�N�G���[�t���O
    String[]  shortageErrFlgRow = new String[vo.getRowCount()]; // �����\�݌ɐ��s���`�F�b�N�G���[�t���O   
    String[]  exceedErrFlgRow   = new String[vo.getRowCount()]; // �����\�݌ɐ����߃`�F�b�N�G���[�t���O   
    String[]  lotNoRow          = new String[vo.getRowCount()]; // ���b�gNo
    Date[]    revDateRow        = new Date[vo.getRowCount()];   // �t�]���t
    Date[]    standardDateRow   = new Date[vo.getRowCount()];   // ���
    String[]  shipTypeRow       = new String[vo.getRowCount()]; // ShipType
    String[]  itemShortNameRow  = new String[vo.getRowCount()]; // �i�ڗ���
    String[]  deliverToRow      = new String[vo.getRowCount()]; // �o�ɐ�
    String[]  locationNameRow   = new String[vo.getRowCount()]; // �o�Ɍ��ۊǏꏊ
// 2008-10-22 D.Nihei ADD START �����e�X�g�w�E194�Ή�
    String[]  deliverToNameRow  = new String[vo.getRowCount()]; // ���ɐ�ۊǏꏊ
// 2008-10-22 D.Nihei ADD END

    // �`�F�b�N�ŕ�����g�p����ϐ���錾
    HashMap data              = null;                         // �߂�l�i�[�p
    Number result             = null;                         // ��������
    Date   revDate            = null;                         // �t�]���t
    Date   standardDate       = null;                         // ���
    Number shipToCanEncQty    = null;                         // ���ɐ�����\��
// 2009-01-26 H.Itou ADD START �{�ԏ�Q��936�Ή�
    String getFreshRetCode    = null;                         // �N�x�������i���������^�[���R�[�h

    // �ȉ��̂��ׂĂ𖞂����ꍇ�A�N�x�`�F�b�N���s�����߁A�N�x�������i���������擾����B
    // �E�ďo��ʋ敪���o��
    // �E���b�g�Ǘ��i
    // �E�i�ڋ敪�����i�̏ꍇ�܂��́A���i�敪�����[�t�ŕi�ڋ敪�������i�̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
      && XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString())
      && (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass)
        || XxwshConstants.PROD_CLASS_CODE_LEAF.equals(prodClass)
          && XxwshConstants.ITEM_TYPE_HALF.equals(itemClass)))
    {
      // �N�x�������i������
      HashMap retHash = XxwshUtility.getFreshPassDate(
                          getOADBTransaction(),
                          deliverToId,
                          itemCode,
                          scheduleArrivalDate,
                          scheduleShipDate);
      getFreshRetCode = (String)retHash.get("retCode");       // �N�x�������i���������^�[���R�[�h
      standardDate    = (Date)retHash.get("manufactureDate"); // �N�x�������i������
    }
// 2009-01-26 H.Itou ADD END

    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̈�s�ڂ��Z�b�g
    vo.first();
    // �S�����[�v
    while (vo.getCurrentRow() != null )
    {
      // �����Ώۍs���擾
      row = (OARow)vo.getCurrentRow();

      // �莝�݌ɐ��E�����\���ꗗ���[�W�����̌��݂̃f�[�^���擾
      canEncQty        = ((Number)row.getAttribute("CanEncQty")).doubleValue();        // ��ʕ\���������\��
// 2008-12-10 H.Itou Mod Start
      canEncQtyBigD        = XxcmnUtility.bigDecimalValue((Number)row.getAttribute("CanEncQty")); // ��ʕ\���������\��
// 2008-12-10 H.Itou Mod End
      lotId            = (Number)row.getAttribute("LotId");                            // ���b�gID
// 2008-12-10 H.Itou Mod Start
      actualQuantity   = ((Number)row.getAttribute("ActualQuantity")).doubleValue();   // ��������
      actualQuantityBk = ((Number)row.getAttribute("ActualQuantityBk")).doubleValue(); // ��ʕ\������������
      actualQuantityBigD   = XxcmnUtility.bigDecimalValue((Number)row.getAttribute("ActualQuantity"));   // ��������
      actualQuantityBkBigD = XxcmnUtility.bigDecimalValue((Number)row.getAttribute("ActualQuantityBk")); // ��ʕ\������������
// 2008-12-10 H.Itou Mod End
      showLotNo        = (String)row.getAttribute("ShowLotNo");                        // �\���p���b�gNo
      productionDate   = (String)row.getAttribute("ProductionDate");                   // �����N����

      // �x�����i�[�p�z��ɏ����l���Z�b�g
      lotRevErrFlgRow[vo.getCurrentRowIndex()]   = XxcmnConstants.STRING_N; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
      freshErrFlgRow[vo.getCurrentRowIndex()]    = XxcmnConstants.STRING_N; // �N�x�����`�F�b�N�G���[�t���O
      shortageErrFlgRow[vo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // �����\�݌ɐ������`�F�b�N�G���[�t���O   
      exceedErrFlgRow[vo.getCurrentRowIndex()]   = XxcmnConstants.STRING_N; // �����\�݌ɐ����߃`�F�b�N�G���[�t���O   
      lotNoRow[vo.getCurrentRowIndex()]          = showLotNo;               // ���b�gNo
      revDateRow[vo.getCurrentRowIndex()]        = null;                    // �t�]���t
      standardDateRow[vo.getCurrentRowIndex()]   = null;                    // ���
      shipTypeRow[vo.getCurrentRowIndex()]       = null;
      deliverToRow[vo.getCurrentRowIndex()]      = deliverTo;               // �o�ɐ�
      itemShortNameRow[vo.getCurrentRowIndex()]  = itemShortName;           // �i�ږ�
      locationNameRow[vo.getCurrentRowIndex()]   = locationName;            // �o�Ɍ�
// 2008-10-22 D.Nihei ADD START �����e�X�g�w�E194�Ή�
      deliverToNameRow[vo.getCurrentRowIndex()]  = deliverToName;           // ���ɐ�
// 2008-10-22 D.Nihei ADD END
      // �������ʂ��ύX����Ă���ꍇ��������0���傫���ꍇ�Ƀ`�F�b�N���s��
      if (actualQuantityBk != actualQuantity
        || (actualQuantity > 0))
      {

        // ���b�g�Ǘ��i�ň������ʂ�0���傫�������N�������ݒ肳��Ă���ꍇ�̂݃��b�g�t�]�h�~�`�F�b�N�A�N�x�����`�F�b�N���s��
        if (XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString())
          && (actualQuantity > 0)
          && !XxcmnUtility.isBlankOrNull(productionDate))
        {
          // �ďo��ʋ敪���o�ׂŕi�ڋ敪�����i�̏ꍇ�������͏��i�敪�����[�t�ŕi�ڋ敪�������i�̏ꍇ
          if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
            && (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass)
            || (XxwshConstants.PROD_CLASS_CODE_LEAF.equals(prodClass)
              && XxwshConstants.ITEM_TYPE_HALF.equals(itemClass))))
          {
            // ���b�g�t�]�h�~�`�F�b�N�����s
            data = XxwshUtility.doCheckLotReversalMov(
                     getOADBTransaction(),
                     XxwshConstants.LOT_BIZ_CLASS_SHIP_INS,
                     itemCode,
                     showLotNo,
                     deliverToId,
                     scheduleArrivalDate,
// 2009-01-22 H.Itou MOD START �{��#1000�Ή�
//                     scheduleShipDate);
                     scheduleShipDate,
                     requestNo
                     );
// 2009-01-22 H.Itou MOD END

            result  = (Number)data.get("result");  // ��������
            revDate = (Date)data.get("revDate");   // �t�]���t

            // API���s���ʂ�1:�G���[�̏ꍇ
            if (!XxwshConstants.RETURN_SUCCESS.equals(result))
            {
              // ���b�g�t�]�h�~�G���[�t���O��Y�ɐݒ�
              lotRevErrFlgRow[vo.getCurrentRowIndex()]     = XxcmnConstants.STRING_Y;
              revDateRow[vo.getCurrentRowIndex()]          = revDate; // �t�]���t
              // �x�����b�Z�[�W�Ŏg�p����ShipType��ݒ�(�o��)
              shipTypeRow[vo.getCurrentRowIndex()]         = XxwshConstants.TOKEN_NAME_DELIVER_TO;

              // �x�����t��NULL�̏ꍇ
              if (XxcmnUtility.isBlankOrNull(warningDate))
              {
                // �x�����t�ƌx���敪�ɒl���Z�b�g���܂��B
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // �x���敪
                warningDate  = revDate;                            // �x�����t
                  
              // �x�����t���t�]���t��菬�������t�̏ꍇ
              } else if (
                XxcmnUtility.chkCompareDate(
                  1,
                  revDate,
                  warningDate))
              {
                // �x�����t�ƌx���敪�ɒl���Z�b�g���܂��B
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // �x���敪
                warningDate  = revDate;                            // �x�����t
              }
            }
// 2009-01-26 H.Itou MOD START �{�ԏ�Q��936�Ή�
//            // �N�x�����`�F�b�N�����s
//            data = XxwshUtility.doCheckFreshCondition(
//                     getOADBTransaction(),
//                     deliverToId,
//                     lotId,
//                     scheduleArrivalDate,
//                     scheduleShipDate);
//
//            result       = (Number)data.get("result");     // ��������
//            standardDate = (Date)data.get("standardDate"); // ���
//
//            // API���s���ʂ�1:�G���[�̏ꍇ
//            if (!XxwshConstants.RETURN_SUCCESS.equals(result))
            // �ȉ��̏ꍇ�A�N�x�����x��
            // �E�N�x�������i���������^�[���R�[�h��0(���^�[���R�[�h1�͏ܖ����Ԃ�0�̏ꍇ�Ȃ̂ŁA�N�x�����`�F�b�N���s��Ȃ��B)
            // �E���������N�x�������i���������Â�
            if (XxcmnConstants.API_RETURN_NORMAL.equals(getFreshRetCode)
              && XxcmnUtility.chkCompareDate(1, standardDate, new Date(productionDate.replaceAll("/", "-"))))
// 2009-01-26 H.Itou MOD END
            {
              // �N�x�����`�F�b�N�G���[�t���O��Y�ɐݒ�
              freshErrFlgRow[vo.getCurrentRowIndex()]      = XxcmnConstants.STRING_Y;
              standardDateRow[vo.getCurrentRowIndex()]     = standardDate; // ���

              // �x�����t��NULL�̏ꍇ
              if (XxcmnUtility.isBlankOrNull(warningDate))
              {
                // �x�����t�ƌx���敪�ɒl���Z�b�g���܂��B
                warningClass = XxwshConstants.WARNING_CLASS_FRESH;   // �x���敪
                warningDate  = standardDate;                         // �x�����t
                  
              // �x�����t���N�x�������i��������菬�������t�̏ꍇ
              } else if (
                XxcmnUtility.chkCompareDate(
                  1,
                  standardDate,
                  warningDate))
              {
                // �x�����t�ƌx���敪�ɒl���Z�b�g���܂��B
                warningClass = XxwshConstants.WARNING_CLASS_FRESH;   // �x���敪
                warningDate  = standardDate;                         // �x�����t
              }
            }            
          // �ďo��ʋ敪���ړ��ŏ��i�敪���h�����N�ŕi�ڋ敪�����i�̏ꍇ
          } else if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn)
            && XxwshConstants.PROD_CLASS_CODE_DRINK.equals(prodClass)
            && XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
          {
            // ���b�g�t�]�h�~�`�F�b�N�����s
            data = XxwshUtility.doCheckLotReversalMov(
                     getOADBTransaction(),
                     XxwshConstants.LOT_BIZ_CLASS_MOVE_INS,
                     itemCode,
                     showLotNo,
                     deliverToId,
                     scheduleArrivalDate,
// 2009-01-22 H.Itou MOD START �{��#1000�Ή�
//                     scheduleShipDate);
                     scheduleShipDate,
                     requestNo
                     );
// 2009-01-22 H.Itou MOD END

            result  = (Number)data.get("result");  // ��������
            revDate = (Date)data.get("revDate");   // �t�]���t

            // API���s���ʂ�1:�G���[�̏ꍇ
            if (!XxwshConstants.RETURN_SUCCESS.equals(result))
            {
              // ���b�g�t�]�h�~�G���[�t���O��Y�ɐݒ�
              lotRevErrFlgRow[vo.getCurrentRowIndex()]     = XxcmnConstants.STRING_Y;
              revDateRow[vo.getCurrentRowIndex()]          = revDate; // �t�]���t
              // �x�����b�Z�[�W�Ŏg�p����ShipType��ݒ�(�ړ�)
              shipTypeRow[vo.getCurrentRowIndex()]         = XxwshConstants.TOKEN_NAME_SHIP_TO;

              // �x�����t��NULL�̏ꍇ
              if (XxcmnUtility.isBlankOrNull(warningDate))
              {
                // �x�����t�ƌx���敪�ɒl���Z�b�g���܂��B
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // �x���敪
                warningDate  = revDate;                            // �x�����t
                  
              // �x�����t���t�]���t��菬�������t�̏ꍇ
              } else if (XxcmnUtility.chkCompareDate(
                          1,
                          revDate,
                          warningDate))
              {
                // �x�����t�ƌx���敪�ɒl���Z�b�g���܂��B
                warningClass = XxwshConstants.WARNING_CLASS_LOT;   // �x���敪
                warningDate  = revDate;                            // �x�����t
              }
            }
          } // �ďo��ʋ敪�A���i�敪�A�i�ڋ敪�ɂ�胍�b�g�t�]�h�~�`�F�b�N�A�N�x�����`�F�b�N���f
        } // ���b�g�Ǘ��i�Ő����N�������ݒ肳��Ă���ꍇ�̂݃��b�g�t�]�h�~�`�F�b�N�A�N�x�����`�F�b�N���s��
        
        // *********************** // 
        // * �����\�������`�F�b�N  *//
        // *********************** //

        // �ďo��ʋ敪���ړ��̏ꍇ
        if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
        {
          // ���ɐ�����\�����擾
          shipToCanEncQty = XxwshUtility.getCanEncQty(
                              getOADBTransaction(),
                              deliverToId,              // ���ɐ�ID
                              itemId,                   // �i��ID
                              lotId,                    // ���b�gID
                              lotCtl.toString(),        // ���b�g�Ǘ�
                              scheduleArrivalDate);     // ���ח\���
// 2008-12-10 H.Itou Add Start
          BigDecimal temp = XxcmnUtility.bigDecimalValue(shipToCanEncQty);
          // ���ɐ�����\�� - (��ʕ\���������� - ������)
// 2008-12-11 H.Itou Add Start
//          temp = temp.subtract(actualQuantityBkBigD).subtract(actualQuantityBigD);
          temp = temp.subtract(actualQuantityBkBigD).add(actualQuantityBigD);
// 2008-12-11 H.Itou Add End
// 2008-12-10 H.Itou Add End
          // ���ɐ�����\�� - (��ʕ\���������� - ������) < 0 �̏ꍇ
// 2008-12-10 H.Itou Mod Start
//          if ((shipToCanEncQty.doubleValue() - (actualQuantityBk - actualQuantity)) < 0)
          if (temp.compareTo(new BigDecimal(0)) == -1)
// 2008-12-10 H.Itou Mod End
          {
            // �����\�������`�F�b�N�G���[�t���O��Y�ɐݒ�
            shortageErrFlgRow[vo.getCurrentRowIndex()]  = XxcmnConstants.STRING_Y;
          }
        } // �����`�F�b�N
        // *********************** // 
        // * �����\�����߃`�F�b�N  *//
        // *********************** //
        // �����\�� + ��ʕ\���������� < �������̏ꍇ
// 2008-12-10 H.Itou Add Start
          // �����\�� + ��ʕ\����������
          BigDecimal temp2 = canEncQtyBigD.add(actualQuantityBkBigD);
// 2008-12-10 H.Itou Add End
// 2008-12-10 H.Itou Mod Start
//        if ((canEncQty + actualQuantityBk) < actualQuantity)
        if (temp2.compareTo(actualQuantityBigD) == -1)
// 2008-12-10 H.Itou Mod End
        {
            // �����\�����߃`�F�b�N�G���[�t���O��Y�ɐݒ�
            exceedErrFlgRow[vo.getCurrentRowIndex()]  = XxcmnConstants.STRING_Y;
        }
      } // �������ʂ��ύX����Ă���ꍇ��������0���傫���ꍇ�Ƀ`�F�b�N���s��
      // ���̃��R�[�h��
      vo.next();
    } // �S�����[�v

    // �x���敪�A�x�����t���Z�b�g
    hrow.setAttribute("WarningClass",warningClass);
    hrow.setAttribute("WarningDate",warningDate);
    
    // �߂�l���Z�b�g
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow);   // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    msg.put("freshErrFlg",      (String[])freshErrFlgRow);    // �N�x�����`�F�b�N�G���[�t���O
    msg.put("shortageErrFlg",   (String[])shortageErrFlgRow); // �����\�݌ɐ������`�F�b�N�G���[�t���O
    msg.put("exceedErrFlg",     (String[])exceedErrFlgRow);   // �����\�݌ɐ����߃`�F�b�N�G���[�t���O
    msg.put("lotNo",            (String[])lotNoRow);          // ���b�gNo
    msg.put("revDate",          (Date[])revDateRow);          // �t�]���t
    msg.put("standardDate",     (Date[])standardDateRow);     // ���
    msg.put("shipType",         (String[])shipTypeRow);       // ShipType
    msg.put("deliverTo",        (String[])deliverToRow);      // �o�ɐ�
    msg.put("itemShortName",    (String[])itemShortNameRow);  // �i�ږ�
    msg.put("locationName",     (String[])locationNameRow);   // �o�Ɍ�
// 2008-10-22 D.Nihei ADD START �����e�X�g�w�E194�Ή�
    msg.put("deliverToName",    (String[])deliverToNameRow);   // ���ɐ�
// 2008-10-22 D.Nihei ADD END

    return msg;
  }

  /***************************************************************************
   * �_�C�A���O��No�{�^���������ɏ������s�����\�b�h�ł��B
   * 
   ***************************************************************************
  */
  public void noBtn()
  {
    // ���b�N�����̂��߃��[���o�b�N���s���܂��B
    XxcmnUtility.rollBack(getOADBTransaction());
  }

  /***************************************************************************
   * �_�C�A���O��Yes�{�^���������ɏ������s�����\�b�h�ł��B
   * 
   ***************************************************************************
  */
  public void yesBtn()
  {
    // ���������\�����[�W�����擾
    OAViewObject hvo                 = getXxwshSearchVO1();
    // ���������\�����[�W������s�ڂ��擾
    OARow hrow                       = (OARow)hvo.first();

    // ���������\�����[�W�����̍��ڂ��擾
    String callPictureKbn            = (String)hrow.getAttribute("CallPictureKbn");           // �ďo��ʋ敪
    String requestNo                 = (String)hrow.getAttribute("RequestNo");                // �˗�No
    String instructQtyUpdFlag        = (String)hrow.getAttribute("InstructQtyUpdFlag");       // �w�����ʍX�V�t���O
    Number itemId                    = (Number)hrow.getAttribute("ItemId");                   // �i��ID
    Number sumReservedQuantityItem   = (Number)hrow.getAttribute("SumReservedQuantityItem");  // �������ʍ��v
    String warningClass              = (String)hrow.getAttribute("WarningClass");             // �x���敪
    Date   warningDate               = (Date)hrow.getAttribute("WarningDate");                // �x�����t
    String weight                    = (String)hrow.getAttribute("Weight");                   // �d��
    String capacity                  = (String)hrow.getAttribute("Capacity");                 // �e��
    String sumQuantity               = (String)hrow.getAttribute("SumQuantity");              // ���v����
    String sumWeight                 = (String)hrow.getAttribute("SumWeight");                // �ύڏd�ʍ��v
    String sumCapacity               = (String)hrow.getAttribute("SumCapacity");              // �ύڗe�ύ��v
    String loadingEfficiencyWeight   = (String)hrow.getAttribute("LoadingEfficiencyWeight");  // �ύڗ�(�d��)
    String loadingEfficiencyCapacity = (String)hrow.getAttribute("LoadingEfficiencyCapacity");// �ύڗ�(�e��)
    String smallQuantity             = (String)hrow.getAttribute("SmallQuantity");            // ������
    String labelQuantity             = (String)hrow.getAttribute("LabelQuantity");            // ���x������
    String exeKbn                    = (String)hrow.getAttribute("ExeKbn");                   // �N���敪
    String packageLiftFlag           = (String)hrow.getAttribute("PackageLiftFlag");            // �ꊇ�����{�^�������t���O

    // ���׏�񃊁[�W�������擾
    OAViewObject lvo                 = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                       = (OARow)lvo.first();

    // ���׏�񃊁[�W�����̍��ڂ��擾
    Number lineId                    = (Number)lrow.getAttribute("LineId");                   // ����ID
    Number headerId                  = (Number)lrow.getAttribute("HeaderId");                 // �w�b�_ID
    String documentTypeCode          = (String)lrow.getAttribute("DocumentTypeCode");         // �����^�C�v
    String itemCode                  = (String)lrow.getAttribute("ItemCode");                 // �i�ڃR�[�h

   // �莝�݌ɐ��E�����\���ꗗ���[�W�����擾
    OAViewObject vo                  = getXxwshStockCanEncQtyVO1();
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̃f�[�^�i�[�p�ϐ�
    OARow row                        = null;

    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̍��ڎ擾�p�ϐ����`
    Number movLotDtlId               = null;                                                // �ړ����b�g�ڍ�ID
    Number actualQuantity            = null;                                                // ��������
    Number lotId                     = null;                                                // ���b�gID
    String showLotNo                 = null;                                                // ���b�gNo(�\���p)

    // �����Ŏg�p����ϐ����`
    String automanualReserveClass    = null;                                                // �����蓮�����敪
    String reservedQuantity          = null;                                                // ��������
    HashMap data                     = new HashMap();                                       // �����p�z��
    HashMap lparam                   = new HashMap();                                       // ���הz��
    HashMap hparam                   = new HashMap();                                       // �w�b�_�z��
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
    boolean updNotifStatusFlag      = false;                                               // �ʒm�X�e�[�^�X�X�V�t���O
// 2008-10-24 D.Nihei ADD END
    // ********************************** // 
    // * �ړ����b�g�ڍדo�^�E�X�V�E�폜����   *//
    // ********************************** //
        
    // �莝�݌ɐ��E�����\���ꗗ���[�W�����̈�s�ڂ��Z�b�g
    vo.first();
    // �S�����[�v
    while ( vo.getCurrentRow() != null )
    {
      // �����Ώۍs���擾
      row = (OARow)vo.getCurrentRow();

      // �����Ώۍs�Ŏg�p����f�[�^���擾
      movLotDtlId       = (Number)row.getAttribute("MovLotDtlId");      // �ړ����b�g�ڍ�ID
      actualQuantity    = (Number)row.getAttribute("ActualQuantity");   // ��������
      lotId             = (Number)row.getAttribute("LotId");            // ���b�gID
      showLotNo         = (String)row.getAttribute("ShowLotNo");        // ���b�gNo

      // �p�����[�^���Z�b�g
      data.put("orderLineId",            lineId);                              // ����ID
      data.put("documentTypeCode",       documentTypeCode);                    // �����^�C�v
      data.put("recordTypeCode",         XxwshConstants.RECORD_TYPE_INST);     // ���R�[�h�^�C�v
      data.put("itemId",                 itemId);                              // �i��ID
      data.put("itemCode",               itemCode);                            // �i�ڃR�[�h
      data.put("lotId",                  lotId);                               // ���b�gID
      data.put("lotNo",                  showLotNo);                           // ���b�gNo
      data.put("actualQuantity",         actualQuantity.toString());           // ���ѐ���
      data.put("actualDate",             null);                                // ���ѓ�
      data.put("automanualReserveClass", XxwshConstants.AM_RESERVE_CLASS_MAN); // �����蓮�����敪
      data.put("movLotDtlId",            movLotDtlId);                         // �ړ����b�g�ڍ�ID
    
      // �������ʂ�0�ňړ����b�g�ڍ�ID���ݒ肳��Ă���ꍇ
      if ((actualQuantity.doubleValue() == 0)
        && !XxcmnUtility.isBlankOrNull(movLotDtlId))
      {
        // �ړ����b�g�ڍ׍폜���������s
        XxwshUtility.deleteActualQuantity(
          getOADBTransaction(),
          movLotDtlId);

      // �������ʂ�0�ȊO�ňړ����b�g�ڍ�ID���ݒ肳��Ă��Ȃ��ꍇ
      } else if ((actualQuantity.doubleValue() != 0)
        && XxcmnUtility.isBlankOrNull(movLotDtlId))
      {
        // �ړ����b�g�ڍדo�^���������s
        XxwshUtility.insXxinvMovLotDetails(
          getOADBTransaction(),
          data);
      // �������ʂ�0�ȊO�ňړ����b�g�ڍ�ID���ݒ肳��Ă���ꍇ
      } else if ((actualQuantity.doubleValue() != 0)
        && !XxcmnUtility.isBlankOrNull(movLotDtlId))
      {
        // �ړ����b�g�ڍ׍X�V���������s
        XxwshUtility.updActualQuantity(
          getOADBTransaction(),
          data);
      }
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
      // DB�������ʂƈ������ʂ��r���ύX������ꍇ
      Number actualQtyBk = (Number)row.getAttribute("ActualQuantityBk");
      Number actualQty   = (Number)row.getAttribute("ActualQuantity");
      if (!XxcmnUtility.isEquals(actualQtyBk, actualQty)) 
      {
        // �ʒm�X�e�[�^�X�X�V�t���O��ON�ɂ���
        updNotifStatusFlag = true;
      }
// 2008-10-24 D.Nihei ADD END
      
      // ���̃��R�[�h��
      vo.next();
    } // �S�����[�v

    // �������ʂ�0�̏ꍇ
    if (sumReservedQuantityItem.doubleValue() == 0)
    {
      reservedQuantity       = null;
      automanualReserveClass = null;
    // �������ʂ�0�ȊO�̏ꍇ
    } else
    {
      reservedQuantity       = sumReservedQuantityItem.toString();
      automanualReserveClass = XxwshConstants.AM_RESERVE_CLASS_MAN;
    }

    // ********************************** // 
    // * ���ׁE�w�b�_�X�V����              *//
    // ********************************** //

    // �ďo��ʋ敪���ړ��̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // �w�����ʍX�V�t���O���X�V�Ώ�(1)�̏ꍇ
      if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
      {
        // ���׍X�V�p�p�����[�^���Z�b�g
        lparam.put("movLineId",              lineId);                             // ����ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // ��������
        lparam.put("warningClass",           warningClass);                       // �x���敪
        lparam.put("warningDate",            warningDate);                        // �x�����t
        lparam.put("automanualReserveClass", automanualReserveClass);             // �����蓮�����敪
        lparam.put("instructQty",            sumReservedQuantityItem.toString()); // �w������
        lparam.put("weight",                 weight);                             // �d��
        lparam.put("capacity",               capacity);                           // �e��

        // �ړ��˗�/�w�����׎w�����ʍX�V����
        XxwshUtility.updMoveLineInstructQty(
          getOADBTransaction(),
          lparam);

        // �w�b�_�X�V�p�p�����[�^���Z�b�g
        hparam.put("movHdrId",                 headerId);                  // �w�b�_ID
        hparam.put("sumQuantity",              sumQuantity);               // ���v����
        hparam.put("smallQuantity",            smallQuantity);             // ������
        hparam.put("labelQuantity",            labelQuantity);             // ���x������
        hparam.put("loadingEfficiencyWeight",  loadingEfficiencyWeight);   // �d�ʐύڌ���
        hparam.put("loadingEfficiencyCapacity",loadingEfficiencyCapacity); // �e�ϐύڌ���
        hparam.put("sumWeight",                sumWeight);                 // ���v�d��
        hparam.put("sumCapacity",              sumCapacity);               // ���v�e��

        // �ړ��˗�/�w���w�b�_�z�ԍ��ڍX�V����
        XxwshUtility.updMoveHeaderDelivery(
          getOADBTransaction(),
          hparam);

      // �w�����ʍX�V�t���O���X�V�Ώ�(1)�ȊO�̏ꍇ
      } else
      {
        // ���׍X�V�p�p�����[�^���Z�b�g
        lparam.put("movLineId",              lineId);                             // ����ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // ��������
        lparam.put("warningClass",           warningClass);                       // �x���敪
        lparam.put("warningDate",            warningDate);                        // �x�����t
        lparam.put("automanualReserveClass", automanualReserveClass);             // �����蓮�����敪

        // �ړ��˗�/�w�����׈������ʍX�V����
        XxwshUtility.updMoveLineReservedQty(
          getOADBTransaction(),
          lparam);

        // �ړ��˗�/�w���w�b�_��ʍX�V���X�V����
        XxwshUtility.updMoveHeaderScreen(
          getOADBTransaction(),
          headerId);
      }
    // �ďo��ʋ敪���ړ��ȊO�̏ꍇ
    } else
    {
      // �w�����ʍX�V�t���O���X�V�Ώ�(1)�̏ꍇ
      if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
      {
        // ���׍X�V�p�p�����[�^���Z�b�g
        lparam.put("orderLineId",            lineId);                             // ����ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // ��������
        lparam.put("warningClass",           warningClass);                       // �x���敪
        lparam.put("warningDate",            warningDate);                        // �x�����t
        lparam.put("automanualReserveClass", automanualReserveClass);             // �����蓮�����敪
        lparam.put("instructQty",            sumReservedQuantityItem.toString()); // �w������
        lparam.put("weight",                 weight);                             // �d��
        lparam.put("capacity",               capacity);                           // �e��

        // �󒍖��׎w�����ʍX�V����
        XxwshUtility.updOrderLineInstructQty(
          getOADBTransaction(),
          lparam);

        // �w�b�_�X�V�p�p�����[�^���Z�b�g
        hparam.put("orderHeaderId",             headerId);                  // �w�b�_ID
        hparam.put("sumQuantity",               sumQuantity);               // ���v����
        hparam.put("smallQuantity",             smallQuantity);             // ������
        hparam.put("labelQuantity",             labelQuantity);             // ���x������
        hparam.put("loadingEfficiencyWeight",   loadingEfficiencyWeight);   // �d�ʐύڌ���
        hparam.put("loadingEfficiencyCapacity", loadingEfficiencyCapacity); // �e�ϐύڌ���
        hparam.put("sumWeight",                 sumWeight);                 // ���v�d��
        hparam.put("sumCapacity",               sumCapacity);               // ���v�e��

        // �󒍃w�b�_�z�ԍ��ڍX�V����
        XxwshUtility.updOrderHeaderDelivery(
          getOADBTransaction(),
          hparam);

      // �w�����ʍX�V�t���O���X�V�Ώ�(1)�ȊO�̏ꍇ
      } else
      {
        // ���׍X�V�p�p�����[�^���Z�b�g
        lparam.put("orderLineId",            lineId);                             // ����ID
        lparam.put("reservedQuantity",       reservedQuantity);                   // ��������
        lparam.put("warningClass",           warningClass);                       // �x���敪
        lparam.put("warningDate",            warningDate);                        // �x�����t
        lparam.put("automanualReserveClass", automanualReserveClass);             // �����蓮�����敪

        // �󒍖��׈������ʍX�V����
        XxwshUtility.updOrderLineReservedQty(
          getOADBTransaction(),
          lparam);

        // �󒍃w�b�_��ʍX�V���X�V����
        XxwshUtility.updOrderHeaderScreen(
          getOADBTransaction(),
          headerId);
      }
    }
// 2008-10-24 D.Nihei MOD START TE080_BPO_600 No22
//    // �w�����ʍX�V�t���O���X�V�Ώ�(1)�̏ꍇ�������͈ꊇ�����{�^�������t���O��'1'��
//    // �������ʂ�0�̏ꍇ
//    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag)
//      || (XxwshConstants.PACKAGE_LIFT_FLAG_INCLUDE.equals(packageLiftFlag)
//        && sumReservedQuantityItem.doubleValue() == 0 ))
    // �w�����ʍX�V�t���O���X�V�Ώ�(1)�̏ꍇ
    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
// 2008-10-24 D.Nihei MOD END
    {
      // �z�ԉ����֐����N��
      XxwshUtility.doCancelCareersSchedule(
        getOADBTransaction(),
        callPictureKbn,
        requestNo);
// 2008-10-24 D.Nihei ADD START TE080_BPO_600 No22
    // �ʒm�X�e�[�^�X�X�V�t���O��ON�̏ꍇ
    } else if (updNotifStatusFlag) 
    {
      // �ʒm�X�e�[�^�X�X�V�֐����N��
      XxwshUtility.updateNotifStatus(
        getOADBTransaction(),
        callPictureKbn,
        requestNo);
// 2008-10-24 D.Nihei ADD END
    }
    // �R�~�b�g����
    XxwshUtility.commit(getOADBTransaction());
    // ******************** // 
    // *  �ŏI�X�V������    * //
    // ******************** //
    String headerUpdateDate = null;
    String lineUpdateDate   = null;
    // �ďo��ʋ敪���ړ��̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
    {
      // �ړ��w�b�_�ŏI�X�V���擾
      headerUpdateDate = XxwshUtility.getMoveHeaderUpdateDate(
                           getOADBTransaction(),
                           headerId);
      // �ړ����׍ŏI�X�V���擾
      lineUpdateDate   = XxwshUtility.getMoveLineUpdateDate(
                           getOADBTransaction(),
                           headerId);
    // �ďo��ʋ敪���ړ��ȊO�̏ꍇ
    } else
    {
      // �󒍃w�b�_�ŏI�X�V���擾
      headerUpdateDate = XxwshUtility.getOrderHeaderUpdateDate(
                           getOADBTransaction(),
                           headerId);
      // �󒍖��׍ŏI�X�V���擾
      lineUpdateDate   = XxwshUtility.getOrderLineUpdateDate(
                           getOADBTransaction(),
                           headerId);
    }
    // ******************** // 
    // *  �ŐV�̏����ĕ\�� * //
    // ******************** //
    HashMap params = new HashMap();
    params.put("LineId",           lineId.toString());
    params.put("callPictureKbn",   callPictureKbn);
    params.put("headerUpdateDate", headerUpdateDate);
    params.put("lineUpdateDate",   lineUpdateDate);
    params.put("exeKbn",           exeKbn);
    initialize(params);

    // �w�����ʍX�V�t���O���X�V�Ώۂ̏ꍇ
    if (XxwshConstants.INSTRUCT_QTY_UPD_FLAG_INCLUDE.equals(instructQtyUpdFlag))
    {
      throw new OAException(
        XxcmnConstants.APPL_XXWSH,
        XxwshConstants.XXWSH32903, 
        null, 
        OAException.INFORMATION, 
        null);

    // �w�����ʍX�V�t���O���X�V�ΏۈȊO�̏ꍇ
    } else 
    {
      throw new OAException(
        XxcmnConstants.APPL_XXWSH,
        XxwshConstants.XXWSH32904, 
        null, 
        OAException.INFORMATION, 
        null);
    }
  }

  /***************************************************************************
   * �˗�No���擾���郁�\�b�h�ł��B
   * @throws OAException
   ***************************************************************************
   */
  public String getReqNo() throws OAException
  {
    // ���׏�񃊁[�W�������擾
    OAViewObject lvo                 = getXxwshLineVO();
    // ���׏�񃊁[�W�����̈�s�ڂ��擾
    OARow lrow                       = (OARow)lvo.first();
    // ���׏�񃊁[�W�����̈˗�No��Ԃ�
    return (String)lrow.getAttribute("RequestNo");
  }

// 2008-12-25 D.Nihei Add Start
  /***************************************************************************
   * ���׍s�R�s�[�������s�����\�b�h�ł��B
   * @param orgVo  - �R�s�[��VO
   * @param destVo - �R�s�[��VO
   ***************************************************************************
   */
  public static void copyRows(OAViewObjectImpl orgVo, OAViewObjectImpl destVo)
  {
    // �ǂ��炩��VO��null�̏ꍇ�͏����I��
    if (orgVo == null || destVo == null)
    {
      return;
    }

    // �R�s�[����VO�̑������擾
    AttributeDef[] attrDefs = orgVo.getAttributeDefs();
    int attrCount = (attrDefs == null) ? 0 : attrDefs.length;
    // �������擾�ł��Ȃ��ꍇ�͏����I��
    if (attrCount == 0)
    {
      return;
    }
    // �R�s�[�p�C�e���[�^���擾���܂��B
    RowSetIterator copyIter = orgVo.findRowSetIterator("copyIter");
    // �R�s�[�p�C�e���[�^��null�̏ꍇ
    if (copyIter == null)
    {
      // �C�e���[�^���쐬���܂��B
      copyIter = orgVo.createRowSetIterator("copyIter");
    }

    boolean rowInserted = false; // �}���t���O
    int lineNum = 1;             // �g�D�ԍ�
    
    // �R�s�[���[�v
    while (copyIter.hasNext())
    {
      // �s���擾
      Row sourceRow = copyIter.next();

      // �s����s�ł��}�������ꍇ
      if (rowInserted)
      {
        // �R�s�[��s�����s�ֈړ����܂��B
        destVo.next();
      }
      // �R�s�[��s���쐬
      Row destRow = destVo.createRow();

      // ������S�ăR�s�[
      for (int i = 0; i < attrCount; i++)
      {
        byte attrKind = attrDefs[i].getAttributeKind();

        if (!(attrKind == AttributeDef.ATTR_ASSOCIATED_ROW ||
              attrKind == AttributeDef.ATTR_ASSOCIATED_ROWITERATOR ||
              attrKind == AttributeDef.ATTR_DYNAMIC))

        {

          String attrName = attrDefs[i].getName();
          if (destVo.lookupAttributeDef(attrName) != null)
          {

            Object attrVal = sourceRow.getAttribute(attrName);

            if (attrVal != null)
            {

              destRow.setAttribute(attrName, attrVal);
            }
          }
        }
      }
      // �R�s�[�����s�}�����܂��B
      destVo.insertRow(destRow);
      // �}���t���O��true
      rowInserted = true;
    }
    // �R�s�[�p�C�e���[�^���N���[�Y
    copyIter.closeRowSetIterator();
    // �R�s�[��VO�����Z�b�g���܂��B
    destVo.reset();

  } // copyRows
// 2008-12-25 D.Nihei Add End

  /**
   * 
   * Container's getter for XxwshPageLayoutPVO1
   */
  public XxwshPageLayoutPVOImpl getXxwshPageLayoutPVO1()
  {
    return (XxwshPageLayoutPVOImpl)findViewObject("XxwshPageLayoutPVO1");
  }

  /**
   * 
   * Container's getter for XxwshSearchVO1
   */
  public XxwshSearchVOImpl getXxwshSearchVO1()
  {
    return (XxwshSearchVOImpl)findViewObject("XxwshSearchVO1");
  }

  /**
   * 
   * Container's getter for XxwshStockCanEncQtyVO1
   */
  public XxwshStockCanEncQtyVOImpl getXxwshStockCanEncQtyVO1()
  {
    return (XxwshStockCanEncQtyVOImpl)findViewObject("XxwshStockCanEncQtyVO1");
  }

  /**
   * 
   * Container's getter for XxwshLineShipVO1
   */
  public XxwshLineShipVOImpl getXxwshLineShipVO1()
  {
    return (XxwshLineShipVOImpl)findViewObject("XxwshLineShipVO1");
  }

  /**
   * 
   * Container's getter for XxwshLineProdVO1
   */
  public XxwshLineProdVOImpl getXxwshLineProdVO1()
  {
    return (XxwshLineProdVOImpl)findViewObject("XxwshLineProdVO1");
  }

  /**
   * 
   * Container's getter for XxwshLineMoveVO1
   */
  public XxwshLineMoveVOImpl getXxwshLineMoveVO1()
  {
    return (XxwshLineMoveVOImpl)findViewObject("XxwshLineMoveVO1");
  }  

  /**
   * 
   * Container's getter for XxwshReserveUnLotVO1
   */
  public XxwshReserveUnLotVOImpl getXxwshReserveUnLotVO1()
  {
    return (XxwshReserveUnLotVOImpl)findViewObject("XxwshReserveUnLotVO1");
  }

  /**
   * 
   * Container's getter for XxwshReserveLotVO1
   */
  public XxwshReserveLotVOImpl getXxwshReserveLotVO1()
  {
    return (XxwshReserveLotVOImpl)findViewObject("XxwshReserveLotVO1");
  }


}