/*============================================================================
* �t�@�C���� : XxwipVolumeActualAMImpl
* �T�v����   : �o�������ѓ��̓A�v���P�[�V�������W���[��
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  ��r���     �V�K�쐬
* 2008-05-12      ��r���     �ύX�v���Ή�(#75)
* 2008-06-12 1.1  ��r���     ST�s��Ή�(#78)
* 2008-06-27 1.2  ��r���     �����e�X�g�w�E�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwip.poplist.server.SlitVOImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;
import itoen.oracle.apps.xxwip.util.XxwipUtility;
import itoen.oracle.apps.xxwip.xxwip200001j.server.XxwipBatchHeaderVOImpl;
import itoen.oracle.apps.xxwip.xxwip200001j.server.XxwipBatchInvestVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OARowValException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �o�������ѓ��͉�ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.2
 ***************************************************************************
 */
public class XxwipVolumeActualAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipVolumeActualAMImpl()
  {
  }
  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("oracle.apps.fnd.framework.itoenprj.test.server", "XxwipVolumeActualAMLocal");
  }

  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void initialize()
  {
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl vo = getXxwipBatchHeaderVO1();
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setWhereClauseParam(0,null);
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setNewRowState(Row.STATUS_INITIALIZED);
    }
    // �o��������PVO�擾
    XxwipVolumeActualPVOImpl pvo = getXxwipVolumeActualPVO1();
    if (pvo.getFetchedRowCount() == 0) 
    {
      pvo.setMaxFetchSize(0);
      pvo.executeQuery();
      pvo.insertRow(pvo.createRow());
      OARow row = (OARow)pvo.first();
      row.setAttribute("RowKey", new Number(1));
      // �����_�����O����
      handleVolumeActualEvent(
        XxcmnConstants.STRING_TRUE, 
        XxcmnConstants.STRING_FALSE, 
        XxcmnConstants.STRING_FALSE, 
        XxcmnConstants.STRING_FALSE,
        XxcmnConstants.STRING_TRUE,
        XxcmnConstants.STRING_TRUE,
        XxcmnConstants.STRING_NO);
    }
  } // initialize

  /***************************************************************************
   * ���b�g���׃{�^���������̏������s�����\�b�h�ł��B
   * @param tabType - �^�u�^�C�v�@0�F�����A1�F�ō�
   * @return HashMap �p�����[�^�Q
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap doDetail(String tabType)
  {
    OARow row = null;
    OAViewObject vo = null;
    Number batchId  = null;
    Number mtlDtlId = null;
    //�p�����[�^�pHashMap����
    HashMap pageParams = new HashMap();
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // �������VO�擾
      vo = getXxwipBatchInvestVO1();
    } else
    {
      // �ō����VO�擾
      vo = getXxwipBatchReInvestVO1();
    }
    // �}���s�擾
    row = (OARow)vo.getFirstFilteredRow("SelectFlag", XxcmnConstants.STRING_Y);
    batchId  = (Number)row.getAttribute("BatchId");
    mtlDtlId = (Number)row.getAttribute("MaterialDetailId");
    if (XxcmnUtility.isBlankOrNull(mtlDtlId)) 
    {
      throw new OARowValException(         
                  OAAttrValException.TYP_VIEW_OBJECT,
                  vo.getName(),
                  row.getKey(),
                  XxcmnConstants.APPL_XXWIP,
                  XxwipConstants.XXWIP10062);
    }
    pageParams.put(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID, batchId);
    pageParams.put(XxwipConstants.URL_PARAM_SEARCH_MTL_DTL_ID, mtlDtlId);

    return pageParams;

  } // doDetail

  /***************************************************************************
   * �����������s�����\�b�h�ł��B
   * @param searchBatchId - �����p�o�b�`ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearch(
    String searchBatchId
    ) throws OAException
  {
    // �K�{�`�F�b�N���s���܂��B
    if (XxcmnUtility.isBlankOrNull(searchBatchId))
    {
      // OA��O���X�g�𐶐����܂��B
      ArrayList exceptions = new ArrayList(2);
      //�g�[�N���𐶐����܂��B
      MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_ITEM, "���������F��zNo") };
      exceptions.add(new OAException(XxcmnConstants.APPL_XXWIP, 
                                     XxwipConstants.XXWIP10008, 
                                     tokens));
      // �����ꂩ�̃`�F�b�N��NG�ł������ꍇ�A�X�^�b�N����OA��O���X���[���܂��B
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    // ���������s���܂��B
    xbhvo.initQuery(searchBatchId);
    OARow row = (OARow)xbhvo.first();
    String trustProcessUnitPriceReject   = XxcmnConstants.STRING_FALSE;
    String othersCostReject              = XxcmnConstants.STRING_FALSE;
    String trustProcessUnitPriceRequired = XxcmnConstants.STRING_NO;
    if (row != null)
    {
      // �������|�b�v���X�g���擾���܂��B
      SlitVOImpl svo = getSlitVO1();
      svo.initQuery(row.getAttribute("RoutingId").toString());

      // �o�������ѐ��������͂̏ꍇ�A�w�}�������R�s�[���܂��B
      String actualQty    = (String)row.getAttribute("ActualQty");
      String directionQty = (String)row.getAttribute("DirectionQty");
      if (XxcmnUtility.isBlankOrNull(actualQty) 
       || XxcmnUtility.chkCompareNumeric(3, actualQty, XxcmnConstants.STRING_ZERO))
      {
        row.setAttribute("ActualQty", directionQty);        
      }
      // ���O�敪���擾���A���Ђ̏ꍇ�A�ϑ����H�P���A���̑����z�𖳌��ɂ��܂��B
      String inOutType = (String)row.getAttribute("InOutType");
      if (XxcmnUtility.isEquals(inOutType, XxwipConstants.IN_OUT_TYPE_JISHA)) 
      {
        trustProcessUnitPriceReject   = XxcmnConstants.STRING_TRUE;
        othersCostReject              = XxcmnConstants.STRING_TRUE;
      } else 
      {
        // �ϑ��v�Z�敪�E�ϑ����H�P�����擾���܂��B
        Date tranDate = null;
        if (XxcmnUtility.isBlankOrNull(row.getAttribute("ProductDate"))) 
        {
          // ���Y�\������Z�b�g
          tranDate = (Date)row.getAttribute("PlanDate");
        } else
        {
          // ���Y�����Z�b�g
          tranDate = (Date)row.getAttribute("ProductDate");
        }
        // �ϑ�������擾���܂��B
        HashMap retMap = XxwipUtility.getStockValue(
                           getOADBTransaction(),
                           (Number)row.getAttribute("ItemId"),
                           (String)row.getAttribute("OrgnCode"),
                           tranDate);
        // ���H�P�������͂���Ă���ꍇ�́A�f�t�H���g�l��ݒ肵�Ȃ��B
        if (XxcmnUtility.isBlankOrNull(row.getAttribute("TrustProcessUnitPrice"))) 
        {
          row.setAttribute("TrustProcessUnitPrice", retMap.get("totalAmount"));
        }
        row.setAttribute("TrustCalculateType", retMap.get("calcType"));
        row.setAttribute("Trust", retMap.get("orgnName"));
        // �ϑ����H�P���̕K�{�ݒ�        
        trustProcessUnitPriceRequired = XxcmnConstants.STRING_UI_ONLY;
      }
    }
    // ���Y�����VO�擾
    XxwipBatchCoProdVOImpl xbcvo = getXxwipBatchCoProdVO1();
    // ���������s���܂��B
    xbcvo.initQuery(searchBatchId);
    // �������VO�擾
    XxwipBatchInvestVOImpl xbivo = getXxwipBatchInvestVO1();
    // ���������s���܂��B
    xbivo.initQuery(searchBatchId);
    OARow row1 = (OARow)xbivo.first();
    if (row1 != null)
    {
      row1.setAttribute("SelectFlag", XxcmnConstants.STRING_Y);
    }
    // �ō����VO�擾
    XxwipBatchReInvestVOImpl xbrivo = getXxwipBatchReInvestVO1();
    // ���������s���܂��B
    xbrivo.initQuery(searchBatchId);
    OARow row2 = (OARow)xbrivo.first();
    if (row2 != null)
    {
      row2.setAttribute("SelectFlag", XxcmnConstants.STRING_Y);
    }
    // ���v���VO�擾
    XxwipBatchTotalVOImpl xbtvo = getXxwipBatchTotalVO1();
    // ���������s���܂��B
    xbtvo.initQuery(searchBatchId);
    // �����_�����O����
    handleVolumeActualEvent(
      XxcmnConstants.STRING_FALSE, 
      XxcmnConstants.STRING_TRUE, 
      XxcmnConstants.STRING_TRUE, 
      XxcmnConstants.STRING_TRUE,
      trustProcessUnitPriceReject,
      othersCostReject,
      trustProcessUnitPriceRequired);

  } // doSearch

  /***************************************************************************
   * ���Y���̃R�s�[�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void copyProductDate()
  {
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl vo = getXxwipBatchHeaderVO1();
    OARow row           = (OARow)vo.first();
    Date productDate    = (Date)row.getAttribute("ProductDate");
    Date makerDate      = (Date)row.getAttribute("MakerDate");
    Date expirationDate = null;
    row.setAttribute("MakerDate", productDate);
    // �������R�s�[�������Ăяo���܂��B
    copyMakerDate();

  } // copyProductDate

  /***************************************************************************
   * �������̃R�s�[�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void copyMakerDate()
  {
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl vo = getXxwipBatchHeaderVO1();
    OARow row           = (OARow)vo.first();
    Date makerDate      = (Date)row.getAttribute("MakerDate");
    Date expirationDate = (Date)row.getAttribute("ExpirationDate");
    Number itemId       = (Number)row.getAttribute("ItemId");
    // �ܖ��������Z�o
    expirationDate = XxwipUtility.getExpirationDate(getOADBTransaction(),
                                                    itemId,
                                                    makerDate);
    row.setAttribute("ExpirationDate", expirationDate);

  } // copyMakerDate

  /***************************************************************************
   * ��ʐ�����s�����\�b�h�ł��B
   * @param goBtnReject          - �u�K�p�v�{�^������
   * @param addRowInvestRender   - �������^�u�u�s�}���v�����_�����O
   * @param addRowReInvestRender - �ō����^�u�u�s�}���v�����_�����O
   * @param addRowCoProdRender   - ���Y�����^�u�u�s�}���v�����_�����O
   * @param trustProcessUnitPriceReject   - �o�b�`�w�b�_���u���H�P���v����
   * @param othersCostReject   - �o�b�`�w�b�_���u���̑����z�v����
   * @param trustProcessUnitPriceRequired - �o�b�`�w�b�_���u���H�P���v�K�{
   ***************************************************************************
   */
  public void handleVolumeActualEvent(
    String goBtnReject,
    String addRowInvestRender,
    String addRowReInvestRender,
    String addRowCoProdRender,
    String trustProcessUnitPriceReject,
    String othersCostReject,
    String trustProcessUnitPriceRequired
  )
  {
    XxwipVolumeActualPVOImpl vo = getXxwipVolumeActualPVO1();
    OARow row       = (OARow)vo.first();
    if (row != null) 
    {
      // �K�p�{�^������
      if (XxcmnConstants.STRING_TRUE.equals(goBtnReject)) 
      {
        row.setAttribute("GoBtnReject", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(goBtnReject)) 
      {
        row.setAttribute("GoBtnReject", Boolean.FALSE);  
      }
      // �������^�u�̍s�}������
      if (XxcmnConstants.STRING_TRUE.equals(addRowInvestRender)) 
      {
        row.setAttribute("AddRowInvestRender", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(addRowInvestRender))  
      {
        row.setAttribute("AddRowInvestRender", Boolean.FALSE);  
      }
      // �ō����^�u�̍s�}������
      if (XxcmnConstants.STRING_TRUE.equals(addRowReInvestRender)) 
      {
        row.setAttribute("AddRowReInvestRender", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(addRowReInvestRender))  
      {
        row.setAttribute("AddRowReInvestRender", Boolean.FALSE);  
      }
      // ���Y�����^�u�̍s�}������
      if (XxcmnConstants.STRING_TRUE.equals(addRowCoProdRender)) 
      {
        row.setAttribute("AddRowCoProdRender", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(addRowCoProdRender)) 
      {
        row.setAttribute("AddRowCoProdRender", Boolean.FALSE);  
      }
      // �ϑ����H�P���̕\������
      if (XxcmnConstants.STRING_TRUE.equals(trustProcessUnitPriceReject)) 
      {
        row.setAttribute("TrustProcessUnitPriceReject", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(trustProcessUnitPriceReject)) 
      {
        row.setAttribute("TrustProcessUnitPriceReject", Boolean.FALSE);  
      }
      // ���̑����z�̕\������
      if (XxcmnConstants.STRING_TRUE.equals(othersCostReject)) 
      {
        row.setAttribute("OthersCostReject", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(othersCostReject)) 
      {
        row.setAttribute("OthersCostReject", Boolean.FALSE);  
      }
      if (XxcmnUtility.isBlankOrNull(trustProcessUnitPriceRequired)) 
      {
        row.setAttribute("TrustProcessUnitPriceRequired", XxcmnConstants.STRING_NO);  
      } else 
      {
        row.setAttribute("TrustProcessUnitPriceRequired", trustProcessUnitPriceRequired);  
      }
      
    }
  } // handleVolumeActualEvent

  /***************************************************************************
   * �s�}���������s�����\�b�h�ł��B
   * 
   * @param tabType - �^�u�^�C�v�@0�F�����A1�F�ō��A2�F���Y��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void addRow(
    String tabType
  ) throws OAException
  {
    OAViewObject vo = null;
    OARow row       = null;

    // �������^�u
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      OAViewObject hdrVo = getXxwipBatchHeaderVO1();
      OARow hdrRow       = (OARow)hdrVo.first();
      // �������VO�擾
      vo  = getXxwipBatchInvestVO1();
      row = (OARow)vo.createRow();
      // Switcher�̐���
      row.setAttribute("ItemNoSwitcher",      "ItemNoInvestEnable");
      row.setAttribute("DeleteSwitcher",      "DeleteInvestEnable");
      row.setAttribute("LineType",            new Number(XxwipConstants.LINE_TYPE_INVEST_NUM));
      row.setAttribute("InventoryLocationId", hdrRow.getAttribute("InventoryLocationId"));
      row.setAttribute("DestinationType",     hdrRow.getAttribute("DestinationType"));
      // �V�ʐ��敪���uY�v�̏ꍇ
      if (XxcmnConstants.STRING_Y.equals(hdrRow.getAttribute("Sinkansentype"))) 
      {
        row.setAttribute("SlitSwitcher", "SlitInvestEnable");
      } else 
      {
        row.setAttribute("SlitSwitcher", "SlitInvestDisable");
      }
      vo.last();
      vo.next();
      vo.insertRow(row);
      row.setNewRowState(Row.STATUS_INITIALIZED);
      // �����_�����O����
      handleVolumeActualEvent(
        null, 
        XxcmnConstants.STRING_FALSE, 
        null, 
        null,
        null,
        null,
        null);
    // �ō����^�u
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      OAViewObject hdrVo = getXxwipBatchHeaderVO1();
      OARow hdrRow       = (OARow)hdrVo.first();
      // �ō����VO�擾
      vo  = getXxwipBatchReInvestVO1();
      row = (OARow)vo.createRow();
      // Switcher�̐���
      row.setAttribute("ItemNoSwitcher",      "ItemNoReInvestEnable");
      row.setAttribute("DeleteSwitcher",      "DeleteReInvestEnable");
      row.setAttribute("LineType",            new Number(XxwipConstants.LINE_TYPE_INVEST_NUM));
      row.setAttribute("InventoryLocationId", hdrRow.getAttribute("InventoryLocationId"));
      row.setAttribute("DestinationType",     hdrRow.getAttribute("DestinationType"));      
      vo.last();
      vo.next();
      vo.insertRow(row);
      row.setNewRowState(Row.STATUS_INITIALIZED);
      // �����_�����O����
      handleVolumeActualEvent(
        null, 
        null, 
        XxcmnConstants.STRING_FALSE, 
        null,
        null,
        null,
        null);
    // ���Y�����^�u
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      // ���Y�����VO�擾
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.createRow();
      row.setAttribute("ItemNoSwitcher", "ItemNoCoProdEnable");
      row.setAttribute("LineType",       new Number(XxwipConstants.LINE_TYPE_CO_PROD_NUM));
      vo.last();
      vo.next();
      vo.insertRow(row);
      row.setNewRowState(Row.STATUS_INITIALIZED);
      // �����_�����O����
      handleVolumeActualEvent(
        null, 
        null, 
        null, 
        XxcmnConstants.STRING_FALSE,
        null,
        null,
        null);
    }
  } // addRow

  /***************************************************************************
   * �K�p�������s�����\�b�h�ł��B
   * @param batchId - �o�b�`ID
   * @param tabType - �^�u�^�C�v�@0�F�����A1:�ō��A2�F���Y��
   ***************************************************************************
   */
  public String apply(
    String batchId,
    String tabType
    )
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag  = false;
    boolean warnFlag = false;
    String  exeType  = XxcmnConstants.STRING_ZERO;

    // �o�b�`�w�b�_���`�F�b�N����
    checkItem(tabType, exceptions);
    // �`�F�b�N��NG�ł������ꍇ�A�X�^�b�N����OA��O���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    } else
    {
      getOADBTransaction().executeCommand("SAVEPOINT " + XxwipConstants.SAVE_POINT_XXWIP200001J);
      // ���b�N�擾����
      getRowLock(batchId);
      // �r������
      chkEexclusiveControl();
      // ���b�g�o�^�E�X�V����
      if (lotExecute()) 
      {
        exeFlag = true;  
      }
      // �X�e�[�^�X�X�V����
      if (updateStatus()) 
      {
        exeFlag = true;  
      }
      // �����i�̊�������
      if (lineAllocation(XxwipConstants.LINE_TYPE_PROD)) 
      {
        exeFlag = true;  
      }
      // �����i�E���Y���̌����o�^����
      if (insertMaterialLine(tabType)) 
      {
        exeFlag = true;  
      }
      // ���Y���̍X�V����
      if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
      {
        // ���Y���E�����i�̌����X�V����
        if (updateMaterialLine(true)) 
        {
          exeFlag = true;  
        }
      } else
      {
        // �����i�̌����X�V����
        if (updateMaterialLine(false)) 
        {
          exeFlag = true;  
        }
      }
      // ���Y���̊�������
      if (lineAllocation(XxwipConstants.LINE_TYPE_CO_PROD)) 
      {
        exeFlag = true;  
      }
      // �������s��ꂽ�ꍇ
      if (exeFlag) 
      {
        // �o�b�`�Z�[�u
        XxwipUtility.saveBatch(getOADBTransaction(), batchId);
        // �݌ɒP���X�V�֐�
        XxwipUtility.updateInvPrice(getOADBTransaction(), batchId);

        // �o�b�`�w�b�_���VO�擾
        XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
        OARow  hdrRow        = (OARow)xbhvo.first();
        String inOutType     = (String)hdrRow.getAttribute("InOutType");
        String trustCalcType = (String)hdrRow.getAttribute("TrustCalculateType");
        // �ϑ���̏ꍇ
        if (XxwipConstants.IN_OUT_TYPE_ITAKU.equals(inOutType)) 
        {
          // �ϑ����H��X�V�֐�
          XxwipUtility.updateTrustPrice(getOADBTransaction(), batchId);
        }
        // �i������
        if (XxcmnConstants.RETURN_WARN.equals(doQtInspection())) 
        {
          warnFlag = true;
        }
      }
    }
    // �x���I��
    if (warnFlag) 
    {
      exeType = XxcmnConstants.RETURN_WARN;
    // ��������I��
    } else if (exeFlag)
    {
      exeType = XxcmnConstants.RETURN_SUCCESS;
    } else 
    {
      exeType = XxcmnConstants.RETURN_NOT_EXE;
    }
    return exeType;
  } // apply

  /***************************************************************************
   * �R�~�b�g�������s�����\�b�h�ł��B
   * @param batchId - �o�b�`ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doCommit(
    String batchId
  ) throws OAException
  {
    // �R�~�b�g
    getOADBTransaction().commit();
    // ����������
    initialize();
    // �Č���
    doSearch(batchId);
    // �o�^�������b�Z�[�W
    throw new OAException(
      XxcmnConstants.APPL_XXWIP,
      XxwipConstants.XXWIP30001, 
      null, 
      OAException.INFORMATION, 
      null);
  } // doCommit

  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doRollBack()
  {
    // �Z�[�u�|�C���g�܂Ń��[���o�b�N���A�R�~�b�g
    XxwipUtility.rollBack(getOADBTransaction(),
                          XxwipConstants.SAVE_POINT_XXWIP200001J);
  } // doRollBack

  /***************************************************************************
   * �`�F�b�N�������s�����\�b�h�ł��B
   * 
   * @param tabType - �^�u�^�C�v�@0�F�����A1:�ō��A2�F���Y��
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void checkItem(
    String tabType,
    ArrayList exceptions
  ) throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    // �o�b�`�w�b�_���VO�擾
    vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    // �V�X�e�����t���擾
    Date currentDate = getOADBTransaction().getCurrentDBDate();
    // ���Y��
    Object productDate = row.getAttribute("ProductDate");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(productDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ProductDate",
                            productDate,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    } else 
    {
      if (!XxcmnUtility.chkCompareDate(2, currentDate, (Date)productDate)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ProductDate",
                              productDate,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10007));
      }
    }
    // ������
    Object makerDate = row.getAttribute("MakerDate");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(makerDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "MakerDate",
                            makerDate,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    }
    // �ܖ�������
    Object expirationDate = row.getAttribute("ExpirationDate");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(expirationDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ExpirationDate",
                            expirationDate,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    }
    // �o��������
    Object actualQty = row.getAttribute("ActualQty");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(actualQty)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ActualQty",
                            actualQty,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    } else
    {
      // ���l�`�F�b�N
      if (!XxcmnUtility.chkNumeric(actualQty, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ActualQty",
                              actualQty,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10061));
      // ���ʃ`�F�b�N
      } else if (XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, actualQty))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ActualQty",
                              actualQty,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10063));
      }
    }
    // �݌ɓ���
    Object entityInner = row.getAttribute("EntityInner");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(entityInner))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "EntityInner",
                            entityInner,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    } else
    {
      if (!XxcmnUtility.chkNumeric(entityInner, 3, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "EntityInner",
                              entityInner,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10061));
      }
    }
    // ���O�敪
    String inOutType = (String)row.getAttribute("InOutType");    
    // ���O�敪���ϑ���̏ꍇ
    if (XxwipConstants.IN_OUT_TYPE_ITAKU.equals(inOutType))
    {
      // �ϑ����H�P�����u�����N�̏ꍇ�A�������o���s���B
      if (XxcmnUtility.isBlankOrNull(row.getAttribute("TrustProcessUnitPrice"))) 
      {
        Date tranDate = null;
        if (XxcmnUtility.isBlankOrNull(row.getAttribute("ProductDate"))) 
        {
          // ���Y�\������Z�b�g
          tranDate = (Date)row.getAttribute("PlanDate");
        } else
        {
          // ���Y�����Z�b�g
          tranDate = (Date)row.getAttribute("ProductDate");
        }
        // �ϑ�������擾���܂��B
        HashMap retMap = XxwipUtility.getStockValue(
                           getOADBTransaction(),
                           (Number)row.getAttribute("ItemId"),
                           (String)row.getAttribute("OrgnCode"),
                           tranDate);
        // �߂�l��0�Ŗ����ꍇ�A�l���Z�b�g
        if (XxcmnUtility.chkCompareNumeric(1, 
                                           retMap.get("totalAmount"), 
                                           XxcmnConstants.STRING_ZERO)) 
        {
          row.setAttribute("TrustProcessUnitPrice", retMap.get("totalAmount"));
        }
        row.setAttribute("TrustCalculateType",    retMap.get("calcType"));
      }
      
      // �ϑ����H�P��
      Object trustProcUnitPrice = row.getAttribute("TrustProcessUnitPrice");
      if (XxcmnUtility.isBlankOrNull(trustProcUnitPrice)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "TrustProcessUnitPrice",
                              trustProcUnitPrice,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10058));
      } else
      {
        if (!XxcmnUtility.chkNumeric(trustProcUnitPrice, 9, 2)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "TrustProcessUnitPrice",
                                trustProcUnitPrice,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10061));
        }
      }
      // ���̑����z
      Object othersCost = row.getAttribute("OthersCost");
      if (!XxcmnUtility.isBlankOrNull(othersCost)) 
      {
        // ���l�`�F�b�N
        if (!XxcmnUtility.chkNumeric(othersCost, 13, 0)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "OthersCost",
                                othersCost,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10061));
        }
      }
    }
    // �������^�u
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // �������VO�擾
      vo  = getXxwipBatchInvestVO1();    
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoInvestEnable");
      // 1�s�������ꍇ�̓G���[�`�F�b�N�͍s��Ȃ��B
      if (row != null) 
      {
        // �i�ڃR�[�h
        Object itemNo = row.getAttribute("ItemNo");
        // �K�{�`�F�b�N
        if (XxcmnUtility.isBlankOrNull(itemNo))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ItemNo",
                                itemNo,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        }
      }
    // �ō����^�u
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      // �ō����VO�擾
      vo  = getXxwipBatchReInvestVO1();
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoReInvestEnable");
      // 1�s�������ꍇ�̓G���[�`�F�b�N�͍s��Ȃ��B
      if (row != null) 
      {
        // �i�ڃR�[�h
        Object itemNo = row.getAttribute("ItemNo");
        // �K�{�`�F�b�N
        if (XxcmnUtility.isBlankOrNull(itemNo))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ItemNo",
                                itemNo,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        }
      }
    // ���Y�����^�u
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      // ���Y�����VO�擾
      vo  = getXxwipBatchCoProdVO1();
      // �X�V�s�擾
      Row[] rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoCoProdDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int i = 0; i < rows.length; i++)
        {
          row = (OARow)rows[i];
          // �݌ɓ���
          entityInner = row.getAttribute("EntityInner");
          // �K�{�`�F�b�N
          if (XxcmnUtility.isBlankOrNull(entityInner))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "EntityInner",
                                  entityInner,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10058));
          } else
          {
            if (!XxcmnUtility.chkNumeric(entityInner, 3, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "EntityInner",
                                    entityInner,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // �o��������
          actualQty = row.getAttribute("ActualQty");
          // �K�{�`�F�b�N
          if (XxcmnUtility.isBlankOrNull(actualQty)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "ActualQty",
                                  actualQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10058));
          } else
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(actualQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ActualQty",
                                    actualQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            // ���ʃ`�F�b�N
            } else if (XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, actualQty))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ActualQty",
                                    actualQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
            }
          }
        }
      }
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoCoProdEnable");
      // 1�s�������ꍇ�̓G���[�`�F�b�N�͍s��Ȃ��B
      if (row != null) 
      {
        // �i�ڃR�[�h
        Object itemNo = row.getAttribute("ItemNo");
        // �K�{�`�F�b�N
        if (XxcmnUtility.isBlankOrNull(itemNo))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ItemNo",
                                itemNo,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        } else
        {
          // �d���`�F�b�N
          // ���̍s�������ꍇ�̓`�F�b�N���Ȃ�
          if ((rows != null) && (rows.length > 0))
          {
            for (int i = 0; i < rows.length; i++)
            {
              Row chkRow = (OARow)rows[i];
              if (XxcmnUtility.isEquals(itemNo, chkRow.getAttribute("ItemNo"))) 
              {
                MessageToken[] tokens = { 
                  new MessageToken(XxwipConstants.TOKEN_ITEM, XxwipConstants.TOKEN_NAME_ITEM) };
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,          
                                      vo.getName(),
                                      row.getKey(),
                                      "ItemNo",
                                      itemNo,
                                      XxcmnConstants.APPL_XXWIP,         
                                      XxwipConstants.XXWIP10023,
                                      tokens));
              }
            }
          }
        }
        // �݌ɓ���
        entityInner = row.getAttribute("EntityInner");
        // �K�{�`�F�b�N
        if (XxcmnUtility.isBlankOrNull(entityInner))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "EntityInner",
                                entityInner,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        } else
        {
          if (!XxcmnUtility.chkNumeric(entityInner, 3, 3)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "EntityInner",
                                  entityInner,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10061));
          }
        }
        // �o��������
        actualQty = row.getAttribute("ActualQty");
        // �K�{�`�F�b�N
        if (XxcmnUtility.isBlankOrNull(actualQty)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ActualQty",
                                actualQty,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        } else
        {
          // ���l�`�F�b�N
          if (!XxcmnUtility.chkNumeric(actualQty, 9, 3)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "ActualQty",
                                  actualQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10061));
          // ���ʃ`�F�b�N
          } else if (XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, actualQty))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "ActualQty",
                                  actualQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10063));
          }
        }
      }    
    }    
  } // checkItem

  /*****************************************************************************
   * �X�e�[�^�X�̍X�V���s���܂��B
   ****************************************************************************/
  public boolean updateStatus()
  {
    OARow row       = null;
    boolean exeFlag = false;

    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    // �Ɩ��X�e�[�^�X
    String dutyStatusCode = (String)row.getAttribute("DutyStatusCode");
    if (!XxwipConstants.DUTY_STATUS_COM.equals(dutyStatusCode)) 
    {
      // �o�b�`ID
      Number batchId  = (Number)row.getAttribute("BatchId");
      exeFlag = XxwipUtility.updateStatus(
                  getOADBTransaction(),
                  batchId);
    }
    return exeFlag;

  } // updateStatus

  /*****************************************************************************
   * ���b�g�̒ǉ��E�X�V���s���܂��B
   * @return �����t���O true�F�������s�Afalse�F���������s
   ****************************************************************************/
  public boolean lotExecute()
  {
    boolean exeFlag = false;

    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String lotNo         = (String)hdrRow.getAttribute("LotNo");         // ���b�gNo
    Date makerDate       = (Date)hdrRow.getAttribute("MakerDate");       // ������
    Date baseMakerDate   = (Date)hdrRow.getAttribute("BaseMakerDate");   // ������(DB)
    Number batchId       = (Number)hdrRow.getAttribute("BatchId");       // �o�b�`ID
    Number itemId        = (Number)hdrRow.getAttribute("ItemId");        // �i��ID
    Number lotId         = (Number)hdrRow.getAttribute("LotId");         // ���b�gID
    String uniqueSign    = (String)hdrRow.getAttribute("UniqueSign");    // �ŗL�L��
    Date expirationDate  = (Date)hdrRow.getAttribute("ExpirationDate");  // �ܖ�������
    String routingNo     = (String)hdrRow.getAttribute("RoutingNo");     // ���C��No
    String slipType      = (String)hdrRow.getAttribute("SlipType");      // �`�[�敪
    String itemClassCode = (String)hdrRow.getAttribute("ItemClassCode"); // �i�ڋ敪

    // �����i�̏ꍇ
    if (!XxcmnUtility.isEquals(makerDate, baseMakerDate)
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Type"),           hdrRow.getAttribute("BaseType"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank1"),          hdrRow.getAttribute("BaseRank1"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank2"),          hdrRow.getAttribute("BaseRank2"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MaterialDesc"),   hdrRow.getAttribute("BaseMaterialDesc"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("EntityInner"),    hdrRow.getAttribute("BaseEntityInner"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ProductDate"),    hdrRow.getAttribute("BaseProductDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MakerDate"),      hdrRow.getAttribute("BaseMakerDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ExpirationDate"), hdrRow.getAttribute("BaseExpirationDate")))
    {
      String entityInner  = (String)hdrRow.getAttribute("EntityInner");    // �݌ɓ���
      String materialDesc = (String)hdrRow.getAttribute("MaterialDesc");   // �E�v
      String qtType       = (String)hdrRow.getAttribute("QtType");         // �����L���敪
      String itemNo       = (String)hdrRow.getAttribute("ItemNo");         // �i�ڃR�[�h
      String type         = (String)hdrRow.getAttribute("Type");           // �^�C�v
      String rank1        = (String)hdrRow.getAttribute("Rank1");          // �����N�P
      String rank2        = (String)hdrRow.getAttribute("Rank2");          // �����N�Q
      // ������ݒ肵�܂��B
      HashMap params = new HashMap();
      params.put("entityInner",    entityInner);
      params.put("materialDesc",   materialDesc);
      params.put("qtType",         qtType);
      params.put("type",           type);
      params.put("rank1",          rank1);
      params.put("rank2",          rank2);
      params.put("itemNo",         itemNo);
      params.put("itemId",         itemId);
      params.put("lotId",          lotId);
      params.put("makerDate",      makerDate);
      params.put("uniqueSign",     uniqueSign);
      params.put("expirationDate", expirationDate);
      params.put("lotNo",          lotNo);
      params.put("slipType",       slipType);
      params.put("routingNo",      routingNo);
      params.put("itemClassCode",  itemClassCode);
      exeFlag = XxwipUtility.lotExecute(
                  getOADBTransaction(),
                  lotNo,
                  hdrRow,
                  XxwipConstants.LINE_TYPE_PROD,
                  params);
    }
    // �����i�̃��b�gNo���Ď擾
    lotNo = (String)hdrRow.getAttribute("LotNo");         // ���b�gNo
    // ���Y�����VO�擾
    XxwipBatchCoProdVOImpl vo  = getXxwipBatchCoProdVO1();
    OARow row = (OARow)vo.first();
    int fetchedRowCount = vo.getFetchedRowCount();
    Row[] coProdRows = vo.getAllRowsInRange();
    if ((coProdRows != null) && (coProdRows.length > 0))
    {
      for (int i = 0; i < coProdRows.length; i++)
      {
        row = (OARow)coProdRows[i];
        // ���Y�����b�gNo
        String coProdLotNo = (String)row.getAttribute("LotNo");
        if (XxcmnUtility.isBlankOrNull(coProdLotNo)
        || !XxcmnUtility.isEquals(lotNo, coProdLotNo)
        || !XxcmnUtility.isEquals(row.getAttribute("Type"),        
                                  row.getAttribute("BaseType"))
        || !XxcmnUtility.isEquals(row.getAttribute("Rank1"),               
                                  row.getAttribute("BaseRank1"))
        || !XxcmnUtility.isEquals(row.getAttribute("Rank2"),               
                                  row.getAttribute("BaseRank2"))
        || !XxcmnUtility.isEquals(row.getAttribute("EntityInner"),         
                                  row.getAttribute("BaseEntityInner")))
        {
          itemId              = (Number)row.getAttribute("ItemId");       // �i��ID
          lotId               = (Number)row.getAttribute("LotId");        // ���b�gID
          String entityInner  = (String)row.getAttribute("EntityInner");  // �݌ɓ���
          String type         = (String)row.getAttribute("Type");         // �^�C�v
          String rank1        = (String)row.getAttribute("Rank1");        // �����N�P
          String rank2        = (String)row.getAttribute("Rank2");        // �����N�Q
          String qtType       = (String)row.getAttribute("QtType");       // �����L���敪
          String itemNo       = (String)row.getAttribute("ItemNo");       // �i�ڃR�[�h
          // ������ݒ肵�܂��B
          HashMap params = new HashMap();
          params.put("entityInner",    entityInner);
          params.put("materialDesc",   null);
          params.put("qtType",         qtType);
          params.put("type",           type);
          params.put("rank1",          rank1);
          params.put("rank2",          rank2);
          params.put("itemNo",         itemNo);
          params.put("itemId",         itemId);
          params.put("lotId",          lotId);
          params.put("makerDate",      makerDate);
          params.put("uniqueSign",     uniqueSign);
          params.put("expirationDate", expirationDate);
          params.put("lotNo",          coProdLotNo);
          params.put("slipType",       slipType);
          params.put("routingNo",      routingNo);
          exeFlag = XxwipUtility.lotExecute(
                      getOADBTransaction(),
                      lotNo,
                      row,
                      XxwipConstants.LINE_TYPE_CO_PROD,
                      params);
        }
      }
    }
    return exeFlag;
  } // lotExecute

  /*****************************************************************************
   * �����̍X�V���s���܂��B
   * @param isCoProd - ���Y���X�V��
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public boolean updateMaterialLine(
    boolean isCoProd
  ) throws OAException 
  {
    boolean exeFlag = false;

    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl hdrVo = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    if (hdrRow == null) 
    {
      return false;
    }
    // �����i�ɕύX���������ꍇ
    /* ----------------------------------
      �^�C�v
      �����N�P
      �����N�Q
      �E�v
      ���Y��
      ������
      �ܖ�������
      �݌ɓ���
      �ϑ��v�Z�敪
      �ϑ����H�P��
      ���̑����z
     ---------------------------------- */
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("Type"),               
                               hdrRow.getAttribute("BaseType"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank1"),              
                               hdrRow.getAttribute("BaseRank1"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank2"),              
                               hdrRow.getAttribute("BaseRank2"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MaterialDesc"),       
                               hdrRow.getAttribute("BaseMaterialDesc"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ProductDate"),        
                               hdrRow.getAttribute("BaseProductDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MakerDate"),          
                               hdrRow.getAttribute("BaseMakerDate"))  
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ExpirationDate"),     
                               hdrRow.getAttribute("BaseExpirationDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("EntityInner"),        
                               hdrRow.getAttribute("BaseEntityInner"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("TrustCalculateType"),    
                               hdrRow.getAttribute("BaseTrustCalculateType"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("TrustProcessUnitPrice"),    
                               hdrRow.getAttribute("BaseTrustProcessUnitPrice"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("OthersCost"),         
                               hdrRow.getAttribute("BaseOthersCost")))
    {
      Number mtlDtlId      = (Number)hdrRow.getAttribute("MaterialDetailId");
      String entityInner   = (String)hdrRow.getAttribute("EntityInner");
      Number lineType      = (Number)hdrRow.getAttribute("LineType");
      Date expirationDate  = (Date)hdrRow.getAttribute("ExpirationDate");
      Date productDate     = (Date)hdrRow.getAttribute("ProductDate");
      Date makerDate       = (Date)hdrRow.getAttribute("MakerDate");
      String type          = (String)hdrRow.getAttribute("Type");
      String rank1         = (String)hdrRow.getAttribute("Rank1");
      String rank2         = (String)hdrRow.getAttribute("Rank2");
      String mtlDesc       = (String)hdrRow.getAttribute("MaterialDesc");
      String trustCalcType = (String)hdrRow.getAttribute("TrustCalculateType");
      String othersCost    = (String)hdrRow.getAttribute("OthersCost");
      String trustProcUnitPrice = (String)hdrRow.getAttribute("TrustProcessUnitPrice");
      // ������ݒ肵�܂��B
      HashMap params = new HashMap();
      params.put("mtlDtlId",       mtlDtlId);
      params.put("lineType",       lineType);
      params.put("type",           type);
      params.put("rank1",          rank1);
      params.put("rank2",          rank2);
      params.put("mtlDesc",        mtlDesc);
      params.put("entityInner",    entityInner);
      params.put("productDate",    productDate);
      params.put("makerDate",      makerDate);
      params.put("expirationDate", expirationDate);
      params.put("trustCalcType",  trustCalcType);
      params.put("othersCost",     othersCost);
      params.put("trustProcUnitPrice", trustProcUnitPrice);
      exeFlag = XxwipUtility.updateMaterialLine(
                  getOADBTransaction(),
                  params);
    }
    // ���Y�����^�u
    if (isCoProd) 
    {
      // ���Y�����VO�擾
      XxwipBatchCoProdVOImpl vo = getXxwipBatchCoProdVO1();
      OARow row       = null;
      // �X�V�s�擾
      Row[] rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoCoProdDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int i = 0; i < rows.length; i++)
        {
          row = (OARow)rows[i];
          // �ύX���������ꍇ
          if (!XxcmnUtility.isEquals(row.getAttribute("Type"),            
                                     row.getAttribute("BaseType"))
           || !XxcmnUtility.isEquals(row.getAttribute("Rank1"),                  
                                     row.getAttribute("BaseRank1"))
           || !XxcmnUtility.isEquals(row.getAttribute("Rank2"),                  
                                     row.getAttribute("BaseRank2"))
           || !XxcmnUtility.isEquals(row.getAttribute("EntityInner"),            
                                     row.getAttribute("BaseEntityInner")))
          {
            String entityInner = (String)row.getAttribute("EntityInner");
            String type        = (String)row.getAttribute("Type");
            String rank1       = (String)row.getAttribute("Rank1");
            String rank2       = (String)row.getAttribute("Rank2");
            Number mtlDtlId    = (Number)row.getAttribute("MaterialDetailId");
            Number lineType    = (Number)row.getAttribute("LineType");
            // ������ݒ肵�܂��B
            HashMap params = new HashMap();
            params.put("type",        type);
            params.put("rank1",       rank1);
            params.put("rank2",       rank2);
            params.put("lineType",    lineType);
            params.put("entityInner", entityInner);
            params.put("mtlDtlId",    mtlDtlId);
            exeFlag = XxwipUtility.updateMaterialLine(
                        getOADBTransaction(),
                        params);
          }
        }
      }
    }
    // ���t���ύX���ꂽ�ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ProductDate"),        
                               hdrRow.getAttribute("BaseProductDate"))) 
    {
      // �o�b�`ID
      Number batchId = (Number)hdrRow.getAttribute("BatchId");
      // �������t�X�V�֐������s���܂��B
      changeTransDateAll(batchId);
    }
    return exeFlag;
  } // updateMaterialLine

  /*****************************************************************************
   * �����̒ǉ����s���܂��B
   * @param tabType - �^�u�^�C�v�@0�F�����A1�F�ō��A2�F���Y��
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public boolean insertMaterialLine(
    String tabType
  ) throws OAException 
  {
    OAViewObject vo  = null;
    OARow row        = null;
    boolean exeFlag  = false;
    String  utkType  = null;
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �o�b�`ID
    Number batchId      = (Number)hdrRow.getAttribute("BatchId");
    Date expirationDate = null;
    Date productDate    = null;
    Date makerDate      = null;
    // �������
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      vo  = getXxwipBatchInvestVO1();
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoInvestEnable");
    // �ō����
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      vo  = getXxwipBatchReInvestVO1();
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoReInvestEnable");
      utkType = XxcmnConstants.STRING_Y;
    // ���Y���̏ꍇ
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoCoProdEnable");
      expirationDate = (Date)hdrRow.getAttribute("ExpirationDate");
      productDate    = (Date)hdrRow.getAttribute("ProductDate");
      makerDate      = (Date)hdrRow.getAttribute("MakerDate");
      row.setAttribute("BatchId", batchId);
    }
    if (row != null) 
    {
      Number itemId   = (Number)row.getAttribute("ItemId");
      Number lineType = (Number)row.getAttribute("LineType");
      String itemUm   = (String)row.getAttribute("ItemUm");
      String slit     = null;
      String type     = null;
      String rank1    = null;
      String rank2    = null;
      String entityInner = null;
      if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
      {
        // ������
        slit = (String)row.getAttribute("Slit");
      } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
      {
        entityInner = (String)row.getAttribute("EntityInner");
        type  = (String)row.getAttribute("Type");
        rank1 = (String)row.getAttribute("Rank1");
        rank2 = (String)row.getAttribute("Rank2");
      }
      // ������ݒ肵�܂��B
      HashMap params = new HashMap();
      params.put("batchId",  batchId);
      params.put("itemId",   itemId);
      params.put("itemUm",   itemUm);
      params.put("type",     type);
      params.put("rank1",    rank1);
      params.put("rank2",    rank2);
      params.put("slit",     slit);
      params.put("utkType",  utkType);
      params.put("lineType", lineType);
      params.put("entityInner",    entityInner);
      params.put("productDate",    productDate);
      params.put("makerDate",      makerDate);
      params.put("expirationDate", expirationDate);
      exeFlag = XxwipUtility.insertMaterialLine(
                  getOADBTransaction(),
                  row,
                  params,
                  tabType);
    }
    return exeFlag;
  } // insertMaterialLine

  /*****************************************************************************
   * �w�肳�ꂽ�s���폜���܂��B
   * @param tabType - �^�u�^�C�v�@0�F�����A1�F�ō��A2�F���Y��
   * @param batchId - ���Y�o�b�`ID
   * @param mtlDtlId - ���Y�����ڍ�ID
   ****************************************************************************/
  public void deleteMaterialLine(
    String tabType,
    String batchId,
    String mtlDtlId
  ) throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    boolean exeFlag = false;

    // �������
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      vo = getXxwipBatchInvestVO1();
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoInvestEnable");
    // �ō����
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      vo = getXxwipBatchReInvestVO1();
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoReInvestEnable");
    // ���Y���̏ꍇ
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      vo = getXxwipBatchCoProdVO1();
      // �}���s�擾
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoCoProdEnable");
    }
    // �}���s�����݂���ꍇ
    if (row != null) 
    {
      // �}���s�폜
      row.remove();
      // �����_�����O����
      handleVolumeActualEvent(
        null, 
        XxcmnConstants.STRING_TRUE, 
        XxcmnConstants.STRING_TRUE, 
        XxcmnConstants.STRING_TRUE,
        null,
        null,
        null);
      // �폜�������b�Z�[�W��\��
      throw new OAException(
        XxcmnConstants.APPL_XXWIP,
        XxwipConstants.XXWIP30002, 
        null, 
        OAException.INFORMATION, 
        null);
    // �X�V�s�폜
    } else
    {
      // ������ݒ肵�܂��B
      HashMap params = new HashMap();
      params.put("batchId",  batchId);
      params.put("mtlDtlId", mtlDtlId);
      exeFlag = XxwipUtility.deleteMaterialLine(
                  getOADBTransaction(),
                  params);
    }
    // �����t���O��TRUE�̏ꍇ
    if (exeFlag) 
    {
      // �o�b�`�Z�[�u
      XxwipUtility.saveBatch(getOADBTransaction(), batchId);
      // �݌ɒP���X�V�֐�
      XxwipUtility.updateInvPrice(getOADBTransaction(), batchId);
      // �R�~�b�g
      getDBTransaction().commit();
      // ����������
      initialize();
      // �Č���
      doSearch(batchId);
      // �폜�������b�Z�[�W��\��
      throw new OAException(
        XxcmnConstants.APPL_XXWIP,
        XxwipConstants.XXWIP30002, 
        null, 
        OAException.INFORMATION, 
        null);
    }
  } // deleteMaterialLine

  /*****************************************************************************
   * �����̓o�^�E�X�V���s���܂��B
   * @param lineType - ���C���^�C�v�@1�F�����i�A2�F���Y��
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public boolean lineAllocation(
    String lineType
  ) throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    boolean exeFlag = false;

    // �w�b�_�����擾���܂��B
    vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    // �e������擾���܂��B
    Date   productDate = (Date)row.getAttribute("ProductDate");        // ���Y��
    String location    = (String)row.getAttribute("DeliveryLocation"); // �ۊǏꏊ
    String whseCode    = (String)row.getAttribute("WipWhseCode");      // �q�ɃR�[�h
    Number batchId     = (Number)row.getAttribute("BatchId");          // �o�b�`ID

    // �����i�̏ꍇ
    if (XxwipConstants.LINE_TYPE_PROD.equals(lineType))
    {
      String lotNo         = (String)row.getAttribute("LotNo");           // ���b�gNo
      Number lotId         = (Number)row.getAttribute("LotId");           // ���b�gID
      Number baseLotId     = (Number)row.getAttribute("BaseLotId");       // ���b�gID(DB)
      Number transId       = (Number)row.getAttribute("TransId");         // �g�����U�N�V����ID
      String actualQty     = (String)row.getAttribute("ActualQty");       // ���ѐ���
      String baseActualQty = (String)row.getAttribute("BaseActualQty");   // ���ѐ���(DB)
      Number mtlDtlId      = (Number)row.getAttribute("MaterialDetailId");// ���Y�����ڍ�ID   
      Number itemId        = (Number)row.getAttribute("ItemId");          // �i��ID   
      Date baseProductDate = (Date)row.getAttribute("BaseProductDate");       // ���Y��(DB)
      // ������ݒ肵�܂��B
      HashMap params = new HashMap();
      params.put("batchId",     batchId);
      params.put("lotId",       lotId);
      params.put("mtlDtlId",    mtlDtlId);
      params.put("actualQty",   XxwipUtility.getRcvShipQty(getOADBTransaction(), "1", itemId, actualQty));
      params.put("location",    location);
      params.put("whseCode",    whseCode);
      params.put("productDate", productDate);
      // �g�����U�N�V����ID��null�̏ꍇ
      if (XxcmnUtility.isBlankOrNull(transId)) 
      {
        // �����ǉ�API�����s���܂��B
        exeFlag = XxwipUtility.insertLineAllocation(
                    getOADBTransaction(),
                    params,
                    lineType);
      // �g�����U�N�V����ID��null�ł͖����ꍇ
      } else 
      {
        // ���b�gID�A���Y���A���ѐ��ʂ��ύX���ꂽ�ꍇ
        if (!XxcmnUtility.isEquals(baseLotId,     lotId)
         || !XxcmnUtility.isEquals(productDate,   baseProductDate)
         || !XxcmnUtility.isEquals(baseActualQty, actualQty)) 
        {
          // ������ݒ肵�܂��B
          params.put("transId",   transId);
          // �����X�VAPI�����s���܂��B
          exeFlag = XxwipUtility.updateLineAllocation(
                      getOADBTransaction(),
                      params,
                      lineType);
        }
      }
    // ���Y���̏ꍇ
    } else 
    {
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.first();
      int fetchedRowCount = vo.getFetchedRowCount();
      Row[] coProdRows = vo.getAllRowsInRange();
      if ((coProdRows != null) && (coProdRows.length > 0))
      {
        for (int i = 0; i < coProdRows.length; i++)
        {
          row = (OARow)coProdRows[i];
          // �e������擾���܂��B
          String lotNo         = (String)row.getAttribute("LotNo");           // ���b�gNo
          Number lotId         = (Number)row.getAttribute("LotId");           // ���b�gID
          Number baseLotId     = (Number)row.getAttribute("BaseLotId");       // ���b�gID(DB)
          Number transId       = (Number)row.getAttribute("TransId");         // �g�����U�N�V����ID
          String actualQty     = (String)row.getAttribute("ActualQty");       // ���ѐ���
          String baseActualQty = (String)row.getAttribute("BaseActualQty");   // ���ѐ���(DB)
          Number mtlDtlId      = (Number)row.getAttribute("MaterialDetailId");// ���Y�����ڍ�ID   
          // ������ݒ肵�܂��B
          HashMap params = new HashMap();
          params.put("batchId",     batchId);
          params.put("lotId",       lotId);
          params.put("mtlDtlId",    mtlDtlId);
          params.put("actualQty",   actualQty);
          params.put("location",    location);
          params.put("whseCode",    whseCode);
          params.put("productDate", productDate);
          // �g�����U�N�V����ID��null�̏ꍇ
          if (XxcmnUtility.isBlankOrNull(transId)) 
          {
            // �����ǉ�API�����s���܂��B
            exeFlag = XxwipUtility.insertLineAllocation(
                        getOADBTransaction(),
                        params,
                        lineType);
          // �g�����U�N�V����ID��null�ł͖����ꍇ
          } else 
          {
            if (!XxcmnUtility.isEquals(baseLotId, lotId) 
             || !XxcmnUtility.isEquals(baseActualQty, actualQty)) 
            {
              // ������ݒ肵�܂��B
              params.put("transId",   transId);
              // �����X�VAPI�����s���܂��B
              exeFlag = XxwipUtility.updateLineAllocation(
                          getOADBTransaction(),
                          params,
                          lineType);
            }
          }
        }
      }
    }
    return exeFlag;
  } // lineAllocation

  /***************************************************************************
   * ���b�N�������s�����\�b�h�ł��B
   * @param batchId - �o�b�`ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getRowLock(
    String batchId
  ) throws OAException 
  {
    String apiName = "getRowLock";
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR gme_cur ");
    sb.append("  IS ");
    sb.append("    SELECT gbh.batch_id batch_id    "); // �o�b�`ID
    sb.append("    FROM   gme_batch_header     gbh "); // ���Y�o�b�`�w�b�_
    sb.append("          ,gme_material_details gmd "); // ���Y�����ڍ�
    sb.append("          ,ic_tran_pnd          itp "); // OPM�ۗ��݌Ƀg�����U�N�V����
    sb.append("    WHERE  gbh.batch_id           = gmd.batch_id  ");
    sb.append("    AND    gmd.material_detail_id = itp.line_id   ");
    sb.append("    AND    gbh.batch_id           = TO_NUMBER(:1) ");
    sb.append("    FOR UPDATE OF gbh.batch_id, gmd.batch_id, itp.doc_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  gme_cur; ");
    sb.append("  CLOSE gme_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setString(i++, batchId);
      
      cstmt.execute();

    } catch (SQLException s) 
    {
      // ���[���o�b�N
      XxwipUtility.rollBack(getOADBTransaction(),
                            XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXWIP, 
                            XxwipConstants.XXWIP10014);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        XxwipUtility.rollBack(getOADBTransaction(), 
                              XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getRowLock

  /***************************************************************************
   * �i���������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String doQtInspection() throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;
    String exeType  = XxcmnConstants.RETURN_NOT_EXE;
    boolean warnFlag   = false; // ����I���t���O
    boolean exeFlag    = false; // �x���I���t���O

    // �w�b�_�����擾���܂��B
    vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    String qtType = (String)row.getAttribute("QtType");
    // �i�������L���敪��Y�̏ꍇ
    if (XxwipConstants.QT_TYPE_ON.equals(qtType)) 
    {
      // �e������擾
      Number lotId   = (Number)row.getAttribute("LotId");
      Number itemId  = (Number)row.getAttribute("ItemId");
      Number batchId = (Number)row.getAttribute("BatchId");
      // �i������No���擾����B
      String qtNumber = getQtNumber(itemId, lotId);
      String retCode  = null;
      // �i������No��Null�̏ꍇ
      if (XxcmnUtility.isBlankOrNull(qtNumber)) 
      {
        // �V�K
        retCode = XxwipUtility.doQtInspection(
                    getOADBTransaction(),
                    "1",
                    lotId,
                    itemId,
                    batchId,
                    null);
        if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
        {
          warnFlag = true;  
        } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
        {
          exeFlag  = true;
        }
      // �������A�o���������ύX���ꂽ�ꍇ
      } else if (!XxcmnUtility.isEquals(row.getAttribute("MakerDate"), 
                                        row.getAttribute("BaseMakerDate"))
              || !XxcmnUtility.isEquals(row.getAttribute("ActualQty"),   
                                        row.getAttribute("BaseActualQty"))) 
      {
        // �X�V
        retCode = XxwipUtility.doQtInspection(
                    getOADBTransaction(),
                    "2",
                    lotId,
                    itemId,
                    batchId,
                    qtNumber);
        if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
        {
          warnFlag = true;  
        } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
        {
          exeFlag  = true;
        }
      }
    }
    // �����i�̐�������ޔ�
    Date bhMakerDate     = (Date)row.getAttribute("MakerDate");
    Date bhBaseMakerDate = (Date)row.getAttribute("BaseMakerDate");
    // ���Y�����
    OAViewObject coProdVo = getXxwipBatchCoProdVO1();
    int fetchedRowCount   = coProdVo.getFetchedRowCount();
    Row[] coProdRows      = coProdVo.getAllRowsInRange();
    if ((coProdRows != null) && (coProdRows.length > 0))
    {
      for (int i = 0; i < coProdRows.length; i++)
      {
        row = (OARow)coProdRows[i];
        // �e������擾���܂��B
        qtType = (String)row.getAttribute("QtType");
        // �i�������L���敪��Y�̏ꍇ
        if (XxwipConstants.QT_TYPE_ON.equals(qtType)) 
        {
          // �e������擾
          Number lotId   = (Number)row.getAttribute("LotId");
          Number itemId  = (Number)row.getAttribute("ItemId");
          Number batchId = (Number)row.getAttribute("BatchId");
          // �i������No���擾����B
          String qtNumber = (String)row.getAttribute("QtNumber");
          String retCode  = null;
          // �i������No��Null�̏ꍇ
          if (XxcmnUtility.isBlankOrNull(qtNumber)) 
          {
            // �V�K
            retCode = XxwipUtility.doQtInspection(
                        getOADBTransaction(),
                        "1",
                        lotId,
                        itemId,
                        batchId,
                        null);
            if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
            {
              warnFlag = true;  
            } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
            {
              exeFlag  = true;
            }
          // �������A�o���������ύX���ꂽ�ꍇ
          } else if (!XxcmnUtility.isEquals(bhMakerDate, bhBaseMakerDate)
                  || !XxcmnUtility.isEquals(row.getAttribute("ActualQty"), 
                                            row.getAttribute("BaseActualQty"))) 
          {
            // �X�V
            exeType = XxwipUtility.doQtInspection(
                        getOADBTransaction(),
                        "2",
                        lotId,
                        itemId,
                        batchId,
                        qtNumber);
            if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
            {
              warnFlag = true;  
            } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
            {
              exeFlag  = true;
            }
          }
        }
      }
    }
    // ����I���t���O��true�̏ꍇ
    if (exeFlag) 
    {
      exeType = XxcmnConstants.RETURN_SUCCESS;
    // �x���I���t���O��true�̏ꍇ
    } else if (warnFlag)
    {
      exeType = XxcmnConstants.RETURN_WARN;
    }
    return exeType;
  } // doQtInspection

  /***************************************************************************
   * �r������`�F�b�N���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void chkEexclusiveControl()
  {
    String apiName  = "chkEexclusiveControl";
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(gbh.batch_id) cnt "); // �o�b�`ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   gme_batch_header     gbh "); // ���Y�o�b�`�w�b�_
      sb.append("        ,gme_material_details gmd "); // ���Y�����ڍ�
      sb.append("  WHERE  gbh.batch_id = gmd.batch_id ");
      sb.append("  AND    gmd.material_detail_id = :2 "); // ���Y�����ڍ�ID
      sb.append("  AND    TO_CHAR(gbh.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    TO_CHAR(gmd.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ; ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      // �w�b�_�����擾���܂��B
      vo  = getXxwipBatchHeaderVO1();
      row = (OARow)vo.first();
      // �e������擾���܂��B
      String gbhLastUpdateDate = (String)row.getAttribute("GbhLastUpdateDate");// �ŏI�X�V��
      String gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate");// �ŏI�X�V��
      Number mtlDtlId          = (Number)row.getAttribute("MaterialDetailId");// ���Y�����ڍ�ID 

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++,  XxcmnUtility.intValue(mtlDtlId));
      cstmt.setString(i++, gbhLastUpdateDate);
      cstmt.setString(i++, gmdLastUpdateDate);
      
      cstmt.execute();
      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0) 
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147);
      }
      // �����i���Y������ PL/SQL�̍쐬���s���܂�
      sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(gmd.material_detail_id) cnt "); // ���Y�����ڍ�ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   gme_material_details gmd    "); // ���Y�����ڍ�
      sb.append("  WHERE  gmd.material_detail_id = :2 "); // ���Y�����ڍ�ID
      sb.append("  AND    TO_CHAR(gmd.last_update_date, 'YYYY/MM/DD HH24:MI:SS') = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ; ");
      sb.append("END; ");
      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      // �������
      vo  = getXxwipBatchInvestVO1();
      row = (OARow)vo.first();
      int fetchedRowCount = vo.getFetchedRowCount();
      // �X�V�s�擾
      Row[] rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoInvestDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // �e������擾���܂��B
          mtlDtlId   = (Number)row.getAttribute("MaterialDetailId");// ���Y�����ڍ�ID 
          gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate"); // �ŏI�X�V��
          //PL/SQL�����s���܂�
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
          cstmt.setString(i++, gmdLastUpdateDate);
      
          cstmt.execute();
          // �r���G���[�̏ꍇ
          if (cstmt.getInt(1) == 0) 
          {
            XxwipUtility.rollBack(getOADBTransaction(),
                                  XxwipConstants.SAVE_POINT_XXWIP200001J);
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10147);
          }
        }
      }
      // �ō����
      vo  = getXxwipBatchReInvestVO1();
      row = (OARow)vo.first();
      fetchedRowCount = vo.getFetchedRowCount();
      // �X�V�s�擾
      rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoReInvestDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // �e������擾���܂��B
          mtlDtlId   = (Number)row.getAttribute("MaterialDetailId");// ���Y�����ڍ�ID 
          gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate"); // �ŏI�X�V��
          //PL/SQL�����s���܂�
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
          cstmt.setString(i++, gmdLastUpdateDate);
          cstmt.execute();
          // �r���G���[�̏ꍇ
          if (cstmt.getInt(1) == 0) 
          {
            doRollBack();
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10147);
          }
        }
      }
      // ���Y�����
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.first();
      fetchedRowCount = vo.getFetchedRowCount();
      // �X�V�s�擾
      rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoCoProdDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // �e������擾���܂��B
          mtlDtlId   = (Number)row.getAttribute("MaterialDetailId");// ���Y�����ڍ�ID 
          gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate"); // �ŏI�X�V��
          //PL/SQL�����s���܂�
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
          cstmt.setString(i++, gmdLastUpdateDate);
      
          cstmt.execute();
          // �r���G���[�̏ꍇ
          if (cstmt.getInt(1) == 0) 
          {
            doRollBack();
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10147);
          }
        }
      }
    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkEexclusiveControl

  /***************************************************************************
   * �o�b�`�ɕR�t���������t���X�V���܂��B
   * @param batchId - �o�b�`ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void changeTransDateAll(
    Number batchId
    ) throws OAException
  {
    String apiName = "changeTransDateAll";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(500);
    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.change_trans_date_all ( ");
    sb.append("    in_batch_id => :1 ");
    sb.append("   ,ov_errbuf   => :2 ");
    sb.append("   ,ov_retcode  => :3 ");
    sb.append("   ,ov_errmsg   => :4 ");
    sb.append("  ); ");
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++,  XxcmnUtility.intValue(batchId)); // �o�b�`ID
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
     
      // PL/SQL���s
      cstmt.execute();

      if (!XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(3))) 
      {
        // ���[���o�b�N
        doRollBack();
        // API�G���[���o�͂���B
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "�������t�X�V�֐�") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    // PL/SQL���s����O�̏ꍇ
    } catch (SQLException s)
    {
      // ���[���o�b�N
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch (SQLException s)
      {
        // ���[���o�b�N
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // changeTransDateAll 

  /*****************************************************************************
   * �������ʃ`�F�b�N���s���܂��B
   * @return String - �x�����b�Z�[�W
   ****************************************************************************/
  public String checkLotQty()
  {
    boolean exeFlag = false;
    boolean makerDateChangeFlag = false; // �������ύX�t���O
    // �_�C�A���O��ʕ\���p���b�Z�[�W
    StringBuffer dialogMsg = new StringBuffer(100);

    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

    // �e����擾
    String lotNo         = (String)hdrRow.getAttribute("LotNo");             // ���b�gNo
    Date makerDate       = (Date)hdrRow.getAttribute("MakerDate");           // ������
    Date baseMakerDate   = (Date)hdrRow.getAttribute("BaseMakerDate");       // ������(DB)
    Number batchId       = (Number)hdrRow.getAttribute("BatchId");           // �o�b�`ID
    Number itemId        = (Number)hdrRow.getAttribute("ItemId");            // �i��ID
    Number lotId         = (Number)hdrRow.getAttribute("LotId");             // ���b�gID
    Number invLocId      = (Number)hdrRow.getAttribute("InventoryLocationId");// �ۊǏꏊID
    String itemClassCode = (String)hdrRow.getAttribute("ItemClassCode");     // �i�ڋ敪
    String actualQty     = (String)hdrRow.getAttribute("ActualQty");         // ���ѐ���
    String baseActualQty = (String)hdrRow.getAttribute("BaseActualQty");     // ���ѐ���(DB)
    String locName       = (String)hdrRow.getAttribute("DeliveryLocationName");

    // �i�ڋ敪���u5:���i�v�ŁA���������ύX���ꂽ�ꍇ
    if ( XxcmnUtility.isEquals(itemClassCode, XxwipConstants.ITEM_TYPE_PROD)
     && !XxcmnUtility.isEquals(makerDate,     baseMakerDate)) 
    {
      // �������ύX�t���O��true�ɂ���
      makerDateChangeFlag = true;
      actualQty = XxcmnConstants.STRING_ZERO;
    }
    /****************************
     * �����i�̏ꍇ
     ****************************/
    // �o���������������ύX���ꂽ�ꍇ
    if (makerDateChangeFlag 
     || XxcmnUtility.chkCompareNumeric(1, baseActualQty, actualQty)) 
    {
      // �������ʃ`�F�b�N�֐��Ōx���������ꍇ
      if (XxcmnConstants.API_RETURN_WARN.equals(XxwipUtility.chkReservedQuantity(
                                                  getOADBTransaction(),
                                                  itemId,
                                                  lotId,
                                                  invLocId,
                                                  baseMakerDate,
                                                  actualQty,
                                                  baseActualQty))) 
      {
        // �g�[�N������
        String itemName = (String)hdrRow.getAttribute("ItemName");
        MessageToken[] tokens = new MessageToken[3];
        tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, locName);  // �[�i�ꏊ����
        tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     itemName); // �i�ږ���
        tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      lotNo);    // ���b�gNo
        
        // ���C�����b�Z�[�W�쐬
        dialogMsg.append(getOADBTransaction().getMessage(XxcmnConstants.APPL_XXCMN, 
                                                         XxcmnConstants.XXCMN10112,
                                                         tokens));
      }
    }
    /****************************
     * ���Y���̏ꍇ
     ****************************/
    // ���Y�����VO�擾
    XxwipBatchCoProdVOImpl vo  = getXxwipBatchCoProdVO1();
    OARow row = (OARow)vo.first();
    Row[] coProdRows = vo.getAllRowsInRange();
    if ((coProdRows != null) && (coProdRows.length > 0))
    {
      for (int i = 0; i < coProdRows.length; i++)
      {
        row = (OARow)coProdRows[i];
        Number coProdItemId        = (Number)row.getAttribute("ItemId");       // �i��ID
        Number coProdLotId         = (Number)row.getAttribute("LotId");        // ���b�gID
        String coProdActualQty     = (String)row.getAttribute("ActualQty");    // ���ѐ���
        String coProdBaseActualQty = (String)row.getAttribute("BaseActualQty");// ���ѐ���(DB)
        // ���ё����������ύX���ꂽ�ꍇ
        if (makerDateChangeFlag 
         || XxcmnUtility.chkCompareNumeric(1, coProdBaseActualQty, coProdActualQty))
        {
          // ���������ύX���ꂽ�ꍇ
          if (makerDateChangeFlag) 
          {
            coProdActualQty = XxcmnConstants.STRING_ZERO;
          }
          // �������ʃ`�F�b�N�֐��Ōx���������ꍇ
          if (XxcmnConstants.API_RETURN_WARN.equals(XxwipUtility.chkReservedQuantity(
                                                      getOADBTransaction(),
                                                      coProdItemId,
                                                      coProdLotId,
                                                      invLocId,
                                                      baseMakerDate,
                                                      coProdActualQty,
                                                      coProdBaseActualQty))) 
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(dialogMsg);
            // �g�[�N������
            String itemName = (String)row.getAttribute("ItemName");
            MessageToken[] tokens = new MessageToken[3];
            tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, locName);  // �[�i�ꏊ����
            tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     itemName); // �i�ږ���
            tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      lotNo);    // ���b�gNo
        
            // ���C�����b�Z�[�W�쐬
            dialogMsg.append(getOADBTransaction().getMessage(XxcmnConstants.APPL_XXCMN, 
                                                             XxcmnConstants.XXCMN10112,
                                                             tokens));
          }
        }
      }
    }
    return dialogMsg.toString();
  } // lotExecute

  /***************************************************************************
   * �����˗�No�̎擾���s�����\�b�h�ł��B
   * @param itemId  - �i��ID
   * @param lotId   - ���b�gID
   * @return String - �����˗�No
   ***************************************************************************
   */
  public String getQtNumber(
    Number itemId,
    Number lotId)
  {
    String apiName  = "getQtNumber";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(500);
      sb.append("DECLARE ");
      sb.append("  lv_qt_number VARCHAR2(10);   ");
      sb.append("BEGIN ");
      sb.append("  SELECT TO_CHAR(xqi.qt_inspect_req_no) "); // �i�������˗�No
      sb.append("  INTO   lv_qt_number ");
      sb.append("  FROM   xxwip_qt_inspection  xqi "); // �i�������˗����A�h�I��
      sb.append("  WHERE  xqi.lot_id  = :1 "); // ���b�gID
      sb.append("  AND    xqi.item_id = :2 "); // �i��ID
      sb.append("  AND    ROWNUM      = 1  ");
      sb.append("  ; ");
      sb.append("    :3 := lv_qt_number;  ");
      sb.append("EXCEPTION ");
      sb.append("  WHEN NO_DATA_FOUND THEN "); // �f�[�^���Ȃ��ꍇ��0
      sb.append("    :3 := null; ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++,  XxcmnUtility.intValue(lotId));
      cstmt.setInt(i++,  XxcmnUtility.intValue(itemId));
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      
      cstmt.execute();

      return cstmt.getString(3);

    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getQtNumber

  /**
   * 
   * Container's getter for TypeVO1
   */
  public OAViewObjectImpl getTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("TypeVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchInvestVO1
   */
  public XxwipBatchInvestVOImpl getXxwipBatchInvestVO1()
  {
    return (XxwipBatchInvestVOImpl)findViewObject("XxwipBatchInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchHeaderVO1
   */
  public XxwipBatchHeaderVOImpl getXxwipBatchHeaderVO1()
  {
    return (XxwipBatchHeaderVOImpl)findViewObject("XxwipBatchHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchReInvestVO1
   */
  public XxwipBatchReInvestVOImpl getXxwipBatchReInvestVO1()
  {
    return (XxwipBatchReInvestVOImpl)findViewObject("XxwipBatchReInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchCoProdVO1
   */
  public XxwipBatchCoProdVOImpl getXxwipBatchCoProdVO1()
  {
    return (XxwipBatchCoProdVOImpl)findViewObject("XxwipBatchCoProdVO1");
  }

  /**
   * 
   * Container's getter for SlitVO1
   */
  public SlitVOImpl getSlitVO1()
  {
    return (SlitVOImpl)findViewObject("SlitVO1");
  }

  /**
   * 
   * Container's getter for XxwipVolumeActualPVO1
   */
  public XxwipVolumeActualPVOImpl getXxwipVolumeActualPVO1()
  {
    return (XxwipVolumeActualPVOImpl)findViewObject("XxwipVolumeActualPVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchTotalVO1
   */
  public XxwipBatchTotalVOImpl getXxwipBatchTotalVO1()
  {
    return (XxwipBatchTotalVOImpl)findViewObject("XxwipBatchTotalVO1");
  }
}