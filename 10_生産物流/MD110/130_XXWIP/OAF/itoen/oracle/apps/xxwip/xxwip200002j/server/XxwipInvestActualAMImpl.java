/*============================================================================
* �t�@�C���� : XxwipInvestActualAMImpl
* �T�v����   : �������ѓ��̓A�v���P�[�V�������W���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-22 1.0  ��r���     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;
import itoen.oracle.apps.xxwip.util.XxwipUtility;
import itoen.oracle.apps.xxwip.xxwip200002j.server.XxwipBatchHeaderVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �������ѓ��̓A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
 ***************************************************************************
 */
public class XxwipInvestActualAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipInvestActualAMImpl()
  {
  }

  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   * 
   * @param searchBatchId - �o�b�`ID
   * @param searchMtlDtlId - ���Y�����ڍ�ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void initialize(
    String searchBatchId,
    String searchMtlDtlId
  ) throws OAException
  {
    // ��������PVO�擾
    XxwipInvestActualPVOImpl pvo = getXxwipInvestActualPVO1();
    if (pvo.getFetchedRowCount() == 0) 
    {
      pvo.setMaxFetchSize(0);
      pvo.executeQuery();
      pvo.insertRow(pvo.createRow());
      OARow row = (OARow)pvo.first();
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("GoBtnReject",              Boolean.TRUE);
      row.setAttribute("ChangeItemInvestReject",   Boolean.TRUE);
      row.setAttribute("ChangeItemReInvestReject", Boolean.TRUE);
      row.setAttribute("InvestItemNameReject",     Boolean.TRUE);
      row.setAttribute("ReInvestItemNameReject",   Boolean.TRUE);
      row.setAttribute("InvestMtlQtyReject",       Boolean.TRUE);
    }
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    // ���������s���܂��B
    xbhvo.initQuery(searchBatchId);
    OARow row = (OARow)xbhvo.first();
    // ���O�敪���擾���A���Ђ̏ꍇ�A�ϑ����H�P���A���̑����z�𖳌��ɂ��܂��B
    String inOutType = (String)row.getAttribute("InOutType");
    if (XxcmnUtility.isEquals(inOutType, XxwipConstants.IN_OUT_TYPE_ITAKU)) 
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
    }
    // ��������PVO�擾
    pvo = getXxwipInvestActualPVO1();
    OARow prow = (OARow)pvo.first();
    if (row != null) 
    {
      prow.setAttribute("GoBtnReject",              Boolean.FALSE);
      prow.setAttribute("ChangeItemInvestReject",   Boolean.FALSE);
      prow.setAttribute("ChangeItemReInvestReject", Boolean.FALSE);
      prow.setAttribute("InvestItemNameReject",     Boolean.FALSE);
      prow.setAttribute("ReInvestItemNameReject",   Boolean.FALSE);
    }
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("ProductDate"))) 
    {
      prow.setAttribute("GoBtnReject", Boolean.TRUE);
    } else
    {
      prow.setAttribute("GoBtnReject", Boolean.FALSE);
    }
    
    // ��������VO���쐬���܂��B
    XxwipItemChoiceInvestVOImpl xicivo = getXxwipItemChoiceInvestVO1();
    xicivo.initQuery(searchMtlDtlId);
    xicivo.first();
    int i = xicivo.getFetchedRowCount();
    if (xicivo.getFetchedRowCount() == 0) 
    {
      xicivo.setMaxFetchSize(0);
      xicivo.executeQuery();
      xicivo.insertRow(xicivo.createRow());
    }
    // �ō�����VO���쐬���܂��B
    XxwipItemChoiceReInvestVOImpl xicrivo = getXxwipItemChoiceReInvestVO1();
    xicrivo.initQuery(searchMtlDtlId);
    xicrivo.first();
    int a = xicrivo.getFetchedRowCount();
    if (xicrivo.getFetchedRowCount() == 0) 
    {
      xicrivo.setMaxFetchSize(0);
      xicrivo.executeQuery();
      xicrivo.insertRow(xicrivo.createRow());
    }
    // �p�����[�^��Null�̏ꍇ�A�G���[�y�[�W�֑J�ڂ���
    if (XxcmnUtility.isBlankOrNull(searchBatchId)
     && XxcmnUtility.isBlankOrNull(searchMtlDtlId)) 
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� *
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500, 
                  null, 
                  OAException.ERROR, 
                  null);      
    }
    
    // �������
    OARow xicivoRow = (OARow)xicivo.first();
    if ((xicivoRow != null) && (XxwipConstants.ITEM_TYPE_SHZ.equals(xicivoRow.getAttribute("ItemClassCode")))) 
    {
      prow.setAttribute("InvestMtlQtyReject", Boolean.FALSE);
    }
    xicivoRow.setAttribute("BatchId", new Number(Integer.parseInt(searchBatchId)));
    // �������b�g���VO�擾
    XxwipInvestLotVOImpl xilvo = getXxwipInvestLotVO1();
    xilvo.initQuery(searchMtlDtlId);

    // �ō����
    OARow xicrivoRow = (OARow)xicrivo.first();
    xicrivoRow.setAttribute("BatchId", new Number(Integer.parseInt(searchBatchId)));
    // �ō����b�g���VO�擾
    XxwipReInvestLotVOImpl xrilvo = getXxwipReInvestLotVO1();
    xrilvo.initQuery(searchMtlDtlId);
  } // initialize

  /***************************************************************************
   * �i�ڕύX�������s�����\�b�h�ł��B
   * 
   * @param searchMtlDtlId - �����p���Y�����ڍ�ID
   * @param tabType - �^�u�^�C�v 0:�����A1:�ō�
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doChange(
    String searchMtlDtlId,
    String tabType
  ) throws OAException
  {
    doCheck(tabType);
    // �������^�u�̏ꍇ
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // �������b�g���VO�擾
      XxwipInvestLotVOImpl vo = getXxwipInvestLotVO1();
      vo.initQuery(searchMtlDtlId);
      OARow row = (OARow)vo.first();
      if (row != null) 
      {
        // ��������PVO�擾
        XxwipInvestActualPVOImpl pvo = getXxwipInvestActualPVO1();
        OARow prow = (OARow)pvo.first();
        if (XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))) 
        {
          prow.setAttribute("InvestMtlQtyReject", Boolean.FALSE);
        } else 
        {
          prow.setAttribute("InvestMtlQtyReject", Boolean.TRUE);
        }
      }
    // �ō����^�u�̏ꍇ
    } else 
    {
      // �ō����b�g���VO�擾
      XxwipReInvestLotVOImpl vo = getXxwipReInvestLotVO1();
      vo.initQuery(searchMtlDtlId);
    }
  } // doChange

  /***************************************************************************
   * �i�ڕύX�������s�����\�b�h�ł��B
   * 
   * @param tabType - �^�u�^�C�v 0:�����A1:�ō�
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doCheck(
    String tabType
  ) throws OAException
  {
    OAViewObject vo = null;
    // �������^�u�̏ꍇ
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // ����LOV�����l�ۊǗp��VO���쐬���܂��B
      vo = getXxwipItemChoiceInvestVO1();
    // �ō����^�u�̏ꍇ
    } else 
    {
      // �ō�LOV�����l�ۊǗp��VO���쐬���܂��B
      vo = getXxwipItemChoiceReInvestVO1();
    }
    OARow row = (OARow)vo.first();
    // �i�ڃR�[�h
    Object itemNo = row.getAttribute("ItemNo");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(itemNo)) 
    {
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "ItemNo",
                  itemNo,
                  XxcmnConstants.APPL_XXWIP,         
                  XxwipConstants.XXWIP10058);
    }       
  } // doCheck

  /***************************************************************************
   * �K�p�������s�����\�b�h�ł��B
   * @param tabType - �^�u�^�C�v�@0�F�����A1:�ō�
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String apply(
    String tabType
  ) throws OAException
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag  = false;
    boolean warnFlag = false;
    String  exeType  = XxcmnConstants.RETURN_NOT_EXE;

    // �`�F�b�N����
    doCheck(tabType);
    // ���׃`�F�b�N����
    checkDetail(tabType, exceptions);
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    getOADBTransaction().executeCommand("SAVEPOINT " + XxwipConstants.SAVE_POINT_XXWIP200001J);

    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    OARow  hdrRow  = (OARow)xbhvo.first();
    String batchId = String.valueOf(hdrRow.getAttribute("BatchId"));

    // ���b�N�擾����
    getRowLock(batchId);

    // �r������
    chkExclusiveControl();

    // �����i�̊�������
    exeFlag = lineAllocation(tabType);

    // �������s��ꂽ�ꍇ
    if (exeFlag) 
    {

      // �o�b�`�Z�[�u
      XxwipUtility.saveBatch(getOADBTransaction(), batchId);

      // �݌ɒP���X�V�֐�
      XxwipUtility.updateInvPrice(getOADBTransaction(), batchId);

      String inOutType = (String)hdrRow.getAttribute("InOutType");
      // �ϑ���̏ꍇ
      if (XxwipConstants.IN_OUT_TYPE_ITAKU.equals(inOutType)) 
      {
        // �ϑ����H��X�V�֐�
        XxwipUtility.updateTrustPrice(getOADBTransaction(), batchId);
      }
    }
    // ��������I��
    if (exeFlag)
    {
      exeType = XxcmnConstants.RETURN_SUCCESS;
    } else 
    {
      exeType = XxcmnConstants.RETURN_NOT_EXE;
    }
    return exeType;
  } // apply

  /***************************************************************************
   * �`�F�b�N�������s�����\�b�h�ł��B
   * @param tabType - �^�u�^�C�v�@0�F�����A1:�ō�
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void checkDetail(
    String tabType,
    ArrayList exceptions
  ) throws OAException 
  {
    String apiName  = "checkDetail";
    OAViewObject vo = null;
    OARow row       = null;
    boolean totalCheckFlag = true;

    // �������^�u
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // �������VO�擾
      vo  = getXxwipInvestLotVO1();    
      // �X�V�s�擾
      Row[] updRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((updRows != null) && (updRows.length > 0))
      {
        for (int i = 0; i < updRows.length; i++)
        {
          row = (OARow)updRows[i];
          totalCheckFlag = true;
          // ���ё���
          Object investedQty = row.getAttribute("InvestedQty");
          // �K�{�`�F�b�N
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "InvestedQty",
                                  investedQty,
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10058));
            totalCheckFlag = false;
          } else
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // ���ʃ`�F�b�N
            } else if (!XxcmnUtility.chkCompareNumeric(2, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // �ߓ�����
          Object returnQty = row.getAttribute("ReturnQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // ���v�l�`�F�b�N
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",","");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
          }
          // �����s�Ǒ���
          Object mtlProdQty = row.getAttribute("MtlProdQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(mtlProdQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(mtlProdQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlProdQty",
                                    mtlProdQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // �Ǝҕs�Ǒ���
          Object mtlMfgQty = row.getAttribute("MtlMfgQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(mtlMfgQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(mtlMfgQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlMfgQty",
                                    mtlMfgQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // ���b�g�X�e�[�^�X�`�F�b�N
          Number lotId = (Number)row.getAttribute("LotId"); // ���b�gID
          if (!XxcmnUtility.isBlankOrNull(investedQty)
           && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
           && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,
                                  vo.getName(),
                                  row.getKey(),
                                  "LotNo",
                                  row.getAttribute("LotNo"),
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10081));
          }
        }
      }
      // �}���s�擾
      Row[] insRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_INS);
      if ((insRows != null) && (insRows.length > 0))
      {
        for (int i = 0; i < insRows.length; i++)
        {
          row = (OARow)insRows[i];
          totalCheckFlag = true;
          // ���ё���
          Object investedQty = row.getAttribute("InvestedQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            totalCheckFlag = false;
          } else
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // ���ʃ`�F�b�N
            } else if (!XxcmnUtility.chkCompareNumeric(2, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // �ߓ�����
          Object returnQty = row.getAttribute("ReturnQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // ���v�l�`�F�b�N
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",","");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
          }
          // �����s�Ǒ���
          Object mtlProdQty = row.getAttribute("MtlProdQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(mtlProdQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(mtlProdQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlProdQty",
                                    mtlProdQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // �Ǝҕs�Ǒ���
          Object mtlMfgQty = row.getAttribute("MtlMfgQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(mtlMfgQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(mtlMfgQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlMfgQty",
                                    mtlMfgQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // ���b�g�X�e�[�^�X�`�F�b�N
          Number lotId = (Number)row.getAttribute("LotId"); // ���b�gID
          if (!XxcmnUtility.isBlankOrNull(investedQty)
           && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
           && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,
                                  vo.getName(),
                                  row.getKey(),
                                  "LotNo",
                                  row.getAttribute("LotNo"),
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10081));
          }
        }
      }
    // �ō����^�u
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      // �ō����VO�擾
      vo  = getXxwipReInvestLotVO1();
      // �X�V�s�擾
      Row[] updRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((updRows != null) && (updRows.length > 0))
      {
        for (int i = 0; i < updRows.length; i++)
        {
          row = (OARow)updRows[i];
          totalCheckFlag = true;
          // ���ё���
          Object investedQty = row.getAttribute("InvestedQty");
          // �K�{�`�F�b�N
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "InvestedQty",
                                  investedQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10058));
            totalCheckFlag = false;
          } else
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // ���ʃ`�F�b�N
            } else if (!XxcmnUtility.chkCompareNumeric(2, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // �ߓ�����
          Object returnQty = row.getAttribute("ReturnQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // ���v�l�`�F�b�N
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",", "");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
            // ���b�g�X�e�[�^�X�`�F�b�N
            Number lotId = (Number)row.getAttribute("LotId"); // ���b�gID
            if (!XxcmnUtility.isBlankOrNull(investedQty)
             && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
             && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,
                                    vo.getName(),
                                    row.getKey(),
                                    "LotNo",
                                    row.getAttribute("LotNo"),
                                    XxcmnConstants.APPL_XXWIP,
                                    XxwipConstants.XXWIP10081));
            }
          }
        }
      }
      // �}���s�擾
      Row[] insRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_INS);
      if ((insRows != null) && (insRows.length > 0))
      {
        for (int i = 0; i < insRows.length; i++)
        {
          row = (OARow)insRows[i];
          totalCheckFlag = true;
          // ���ё���
          Object investedQty = row.getAttribute("InvestedQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            totalCheckFlag = false;
          } else
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // ���ʃ`�F�b�N
            } else if (!XxcmnUtility.chkCompareNumeric(1, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // �ߓ�����
          Object returnQty = row.getAttribute("ReturnQty");
          // ���͂���Ă���ꍇ�A�`�F�b�N���s���B
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // ���l�`�F�b�N
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // ���v�l�`�F�b�N
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",","");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
          }
          // ���b�g�X�e�[�^�X�`�F�b�N
          Number lotId = (Number)row.getAttribute("LotId"); // ���b�gID
          if (!XxcmnUtility.isBlankOrNull(investedQty)
           && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
           && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,
                                  vo.getName(),
                                  row.getKey(),
                                  "LotNo",
                                  row.getAttribute("LotNo"),
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10081));
          }
        }
      }
    }
  } // checkDetail

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
    sb.append("    SELECT gbh.batch_id batch_id     "); // �o�b�`ID
    sb.append("    FROM   gme_batch_header      gbh "); // ���Y�o�b�`�w�b�_
    sb.append("          ,gme_material_details  gmd "); // ���Y�����ڍ�
    sb.append("          ,xxwip_material_detail xmd "); // ���Y�����ڍ׃A�h�I��
    sb.append("          ,ic_tran_pnd           itp "); // OPM�ۗ��݌Ƀg�����U�N�V����
    sb.append("    WHERE  gbh.batch_id           = gmd.batch_id           ");
    sb.append("    AND    gmd.material_detail_id = itp.line_id            ");
    sb.append("    AND    gmd.material_detail_id = xmd.material_detail_id ");
    sb.append("    AND    gbh.batch_id           = TO_NUMBER(:1)          ");
    sb.append("    FOR UPDATE OF gbh.batch_id");
    sb.append("                 ,gmd.batch_id");
    sb.append("                 ,xmd.batch_id");
    sb.append("                 ,itp.doc_id NOWAIT; ");
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
                            XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                              XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getRowLock

  /***************************************************************************
   * �r������`�F�b�N���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void chkExclusiveControl()
  {
    String apiName  = "chkExclusiveControl";
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(xmd.batch_id) cnt "); // �o�b�`ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   xxwip_material_detail xmd    "); // ���Y�����ڍ׃A�h�I��
      sb.append("  WHERE  xmd.mtl_detail_addon_id = :2 "); // ���Y�����ڍ׃A�h�I��ID
      sb.append("  AND    TO_CHAR(xmd.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      // �������
      vo  = getXxwipInvestLotVO1();
      row = (OARow)vo.first();
      Number mtlDtlAddOnId     = null; 
      String xmdLastUpdateDate = null; 
      int fetchedRowCount = vo.getFetchedRowCount();
      int i = 1;
      // �X�V�s�擾
      Row[] rows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // �e������擾���܂��B
          mtlDtlAddOnId     = (Number)row.getAttribute("MtlDetailAddonId");// ���Y�����ڍ�ID 
          xmdLastUpdateDate = (String)row.getAttribute("XmdLastUpdateDate"); // �ŏI�X�V��
          //PL/SQL�����s���܂�
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlAddOnId));
          cstmt.setString(i++, xmdLastUpdateDate);
      
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
      // �ō����
      vo  = getXxwipReInvestLotVO1();
      row = (OARow)vo.first();
      fetchedRowCount = vo.getFetchedRowCount();
      // �X�V�s�擾
      rows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // �e������擾���܂��B
          mtlDtlAddOnId     = (Number)row.getAttribute("MtlDetailAddonId");  // ���Y�����ڍ�ID 
          xmdLastUpdateDate = (String)row.getAttribute("XmdLastUpdateDate"); // �ŏI�X�V��
          //PL/SQL�����s���܂�
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlAddOnId));
          cstmt.setString(i++, xmdLastUpdateDate);
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
                            XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                              XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkEexclusiveControl

  /*****************************************************************************
   * �����̓o�^�E�X�V���s���܂��B
   * @param tabType - �^�u�^�C�v�@0�F�����A1�F�ō�
   * @return �����t���O true�F�������s�Afalse�F���������s
   * @throws OAException - OA��O
   ****************************************************************************/
  public boolean lineAllocation(
    String tabType
  ) throws OAException 
  {

    String apiName  = "lineAllocation";
    OAViewObject vo = null;
    // �����t���O
    boolean exeFlag = false;
    // �w�b�_�����擾���܂��B
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �e������擾���܂��B
    Date   productDate = (Date)hdrRow.getAttribute("ProductDate");        // ���Y��
    String location    = (String)hdrRow.getAttribute("DeliveryLocation"); // �[�i�ꏊ
    String whseCode    = (String)hdrRow.getAttribute("WipWhseCode");      // �q�ɃR�[�h
    Number batchId     = (Number)hdrRow.getAttribute("BatchId");          // �o�b�`ID

    // �������^�u�̏ꍇ
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType))
    {
      // �������b�g�����擾���܂��B
      vo  = getXxwipInvestLotVO1();
    // �ō����^�u�̏ꍇ
    } else
    {
      // �ō����b�g�����擾���܂��B
      vo  = getXxwipReInvestLotVO1();
    }

    /****************************************
     * �}������
     *****************************************/
    // �}���p��PL/SQL�̍쐬���s���܂�
    StringBuffer insSb = new StringBuffer(1000);
    insSb.append("BEGIN ");
    insSb.append("  INSERT INTO xxwip_material_detail( ");// ���Y�����ڍ׃A�h�I��
    insSb.append("    mtl_detail_addon_id    ");// ���Y�����ڍ׃A�h�I��ID
    insSb.append("   ,batch_id               ");// �o�b�`ID
    insSb.append("   ,material_detail_id     ");// ���Y�����ڍ�ID
    insSb.append("   ,item_id                ");// �i��ID
    insSb.append("   ,lot_id                 ");// ���b�gID
    insSb.append("   ,instructions_qty       ");// �w������
    insSb.append("   ,invested_qty           ");// ��������
    insSb.append("   ,return_qty             ");// �ߓ�����
    insSb.append("   ,mtl_prod_qty           ");// ���ސ����s�ǐ�
    insSb.append("   ,mtl_mfg_qty            ");// ���ދƎҕs�ǐ�
    insSb.append("   ,location_code          ");// ��z�q�ɃR�[�h
    insSb.append("   ,plan_type              ");// �\��敪
    insSb.append("   ,plan_number            ");// �ԍ�
    insSb.append("   ,created_by             ");// �쐬��
    insSb.append("   ,creation_date          ");// �쐬��
    insSb.append("   ,last_updated_by        ");// �ŏI�X�V��
    insSb.append("   ,last_update_date       ");// �ŏI�X�V��
    insSb.append("   ,last_update_login      ");// �ŏI�X�V���O�C��
    insSb.append("   ,request_id             ");// �v��ID
    insSb.append("   ,program_application_id ");// �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    insSb.append("   ,program_id             ");// �R���J�����g�E�v���O����ID
    insSb.append("   ,program_update_date    ");// �v���O�����X�V��
    insSb.append("  ) VALUES ( ");
    insSb.append("    xxwip_mtl_detail_addon_id_s1.NEXTVAL ");// ���Y�����ڍ׃A�h�I��ID
    insSb.append("   ,:1                  ");// �o�b�`ID
    insSb.append("   ,:2                  ");// ���Y�����ڍ�ID
    insSb.append("   ,:3                  ");// �i��ID
    insSb.append("   ,:4                  ");// ���b�gID
    insSb.append("   ,null                ");// �w������
    insSb.append("   ,:5                  ");// ��������
    insSb.append("   ,NVL(:6, 0)          ");// �ߓ�����
    insSb.append("   ,NVL(:7, 0)          ");// ���ސ����s�ǐ�
    insSb.append("   ,NVL(:8, 0)          ");// ���ދƎҕs�ǐ�
    insSb.append("   ,:9                  ");// ��z�q�ɃR�[�h
    insSb.append("   ,'4'                 ");// �\��敪
    insSb.append("   ,NULL                ");// �ԍ�
    insSb.append("   ,fnd_global.user_id  ");// �쐬��
    insSb.append("   ,SYSDATE             ");// �쐬��
    insSb.append("   ,fnd_global.user_id  ");// �ŏI�X�V��
    insSb.append("   ,SYSDATE             ");// �ŏI�X�V��
    insSb.append("   ,fnd_global.login_id ");// �ŏI�X�V���O�C��
    insSb.append("   ,NULL                ");// �v��ID
    insSb.append("   ,NULL                ");// �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    insSb.append("   ,NULL                ");// �R���J�����g�E�v���O����ID
    insSb.append("   ,NULL                ");// �v���O�����X�V��
    insSb.append("  ); ");
    insSb.append("  :10 := TO_CHAR(TO_NUMBER(:11) - TO_NUMBER(NVL(:12, 0))); ");
    insSb.append("END; ");
    // �}���s�擾
    Row[] insRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_INS);
    if ((insRows != null) && (insRows.length > 0))
    {
      //PL/SQL�̐ݒ���s���܂�
      CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                  insSb.toString(),
                                  OADBTransaction.DEFAULT);
      String actualQty = null;
      OARow  row       = null;
      for (int i = 0; i < insRows.length; i++)
      {
        row = (OARow)insRows[i];
        String investedQty = (String)row.getAttribute("InvestedQty");    // ���ѐ���
        if (!XxcmnUtility.isBlankOrNull(investedQty)) 
        {
          Number mtlDtlId      = (Number)row.getAttribute("MaterialDetailId");   // ���Y�����ڍ�ID   
          Number movLotDtlId   = (Number)row.getAttribute("MovLotDtlId");        // �ړ����b�g�ڍ׏ڍ�ID   
          String xmldActualQty = (String)row.getAttribute("XmldActualQuantity"); // �ړ����b�g�ڍ׎��ѐ���   
          String itemType      = (String)row.getAttribute("ItemClassCode");      // �i�ڃ^�C�v
          Number itemId        = (Number)row.getAttribute("ItemId");             // �i��ID
          String itemNo        = (String)row.getAttribute("ItemNo");             // �i�ڃR�[�h
          Number lotId         = (Number)row.getAttribute("LotId");              // ���b�gID
          String lotNo         = (String)row.getAttribute("LotNo");              // ���b�gNo
          String returnQty     = (String)row.getAttribute("ReturnQty");          // �ߓ�����
          String mtlProdQty    = XxcmnConstants.STRING_ZERO;                     // �����s�Ǒ���
          String mtlMfgQty     = XxcmnConstants.STRING_ZERO;                     // �Ǝҕs�Ǒ���
          if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType))
          {
            mtlProdQty = (String)row.getAttribute("MtlProdQty");     // �����s�Ǒ���
            mtlMfgQty  = (String)row.getAttribute("MtlMfgQty");      // �Ǝҕs�Ǒ���
          }
          try
          {
            //PL/SQL�����s���܂�
            int x = 1;
            cstmt.setInt(x++, XxcmnUtility.intValue(batchId));
            cstmt.setInt(x++, XxcmnUtility.intValue(mtlDtlId));
            cstmt.setInt(x++, XxcmnUtility.intValue(itemId));
            cstmt.setInt(x++, XxcmnUtility.intValue(lotId));
            cstmt.setString(x++, investedQty);
            cstmt.setString(x++, returnQty);
            cstmt.setString(x++, mtlProdQty);
            cstmt.setString(x++, mtlMfgQty);
            cstmt.setString(x++, location);
            cstmt.registerOutParameter(x++, Types.NUMERIC); 
            cstmt.setString(x++, investedQty);
            cstmt.setString(x++, returnQty);

            // ���Y�����ڍ׃A�h�I���ɍs��ǉ����܂��B
            cstmt.execute();
            actualQty = cstmt.getString(10);
            exeFlag = true;
          } catch (SQLException s) 
          {
            // ���[���o�b�N
            XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
            XxcmnUtility.writeLog(getOADBTransaction(),
                                  XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
              // ���[���o�b�N
              XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
              XxcmnUtility.writeLog(getOADBTransaction(),
                                    XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                                    s.toString(),
                                    6);
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxcmnConstants.XXCMN10123);
            } 
          }

          // ������ݒ肵�܂��B
          HashMap params = new HashMap();
          params.put("batchId",      batchId);
          params.put("itemId",       itemId);
          params.put("itemNo",       itemNo);
          params.put("lotNo",        lotNo);
          params.put("lotId",        lotId);
          params.put("mtlDtlId",     mtlDtlId);
          params.put("movLotDtlId",  movLotDtlId);
          params.put("actualQty",    actualQty);
          params.put("xmldActualQty",xmldActualQty);
          params.put("location",     location);
          params.put("whseCode",     whseCode);
          params.put("productDate",  productDate);
           
          // �����ǉ�API�����s���܂��B
          XxwipUtility.insertLineAllocation(
            getOADBTransaction(),
            params,
            XxwipConstants.LINE_TYPE_INVEST);
          // �ړ����b�g�ڍׂւ̏����ݏ������s���܂��B
          XxwipUtility.movLotExecute(
            getOADBTransaction(),
            params);
        }
      }        
    }

    // �X�V�p��PL/SQL�̍쐬���s���܂�
    StringBuffer updSb = new StringBuffer(1000);
    updSb.append("BEGIN ");
    updSb.append("  UPDATE xxwip_material_detail xmd "); // ���Y�����ڍ׃A�h�I��
    updSb.append("  SET    xmd.invested_qty      = :1 "); // ���ё���
    updSb.append("        ,xmd.return_qty        = :2 "); // �ߓ�����
    updSb.append("        ,xmd.mtl_prod_qty      = :3 "); // �����s�Ǒ���
    updSb.append("        ,xmd.mtl_mfg_qty       = :4 "); // �Ǝҕs�Ǒ���
    updSb.append("        ,xmd.last_updated_by   = fnd_global.user_id "); // �ŏI�X�V��
    updSb.append("        ,xmd.last_update_date  = SYSDATE ");            // �ŏI�X�V��
    updSb.append("        ,xmd.last_update_login = fnd_global.login_id "); // �ŏI�X�V���O�C��
    updSb.append("  WHERE  xmd.mtl_detail_addon_id = :5 ; ");
    updSb.append("  :6 := TO_CHAR(TO_NUMBER(:7) - TO_NUMBER(NVL(:8, 0))); ");
    updSb.append("END; ");

    // �폜�p��PL/SQL�̍쐬���s���܂�
    StringBuffer delSb = new StringBuffer(1000);
    delSb.append("BEGIN ");
    delSb.append("  DELETE xxwip_material_detail xmd ");      // ���Y�����ڍ׃A�h�I��
    delSb.append("  WHERE  xmd.mtl_detail_addon_id  = :1; "); 
    delSb.append("END; ");

    // �X�V�s�擾
    Row[] updRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
    if ((updRows != null) && (updRows.length > 0))
    {
      String actualQty = null;
      OARow  row       = null;
      for (int i = 0; i < updRows.length; i++)
      {
        row = (OARow)updRows[i];
        String instructionsQty = (String)row.getAttribute("InstructionsQty"); // �w������
        String investedQty     = (String)row.getAttribute("InvestedQty");     // ���ѐ���
        String returnQty       = (String)row.getAttribute("ReturnQty");       // �ߓ�����
        String baseInvestedQty = (String)row.getAttribute("BaseInvestedQty"); // �����ѐ���
        String baseReturnQty   = (String)row.getAttribute("BaseReturnQty");   // ���ߓ�����
        String mtlProdQty      = XxcmnConstants.STRING_ZERO;     // �����s�Ǒ���
        String mtlMfgQty       = XxcmnConstants.STRING_ZERO;     // �Ǝҕs�Ǒ���
        String baseMtlProdQty  = XxcmnConstants.STRING_ZERO;     // �������s�Ǒ���
        String baseMtlMfgQty   = XxcmnConstants.STRING_ZERO;     // ���Ǝҕs�Ǒ���
        if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType))
        {
          mtlProdQty     = (String)row.getAttribute("MtlProdQty");     // �����s�Ǒ���
          mtlMfgQty      = (String)row.getAttribute("MtlMfgQty");      // �Ǝҕs�Ǒ���
          baseMtlProdQty = (String)row.getAttribute("BaseMtlProdQty");     // �������s�Ǒ���
          baseMtlMfgQty  = (String)row.getAttribute("BaseMtlMfgQty");      // ���Ǝҕs�Ǒ���
        }
        // �ߓ�������Null�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(returnQty)) 
        {
           returnQty = XxcmnConstants.STRING_ZERO; 
        }
        // �����s�Ǒ�����Null�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(mtlProdQty)) 
        {
           mtlProdQty = XxcmnConstants.STRING_ZERO; 
        }
        // �Ǝҕs�Ǒ�����Null�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(mtlMfgQty)) 
        {
           mtlMfgQty = XxcmnConstants.STRING_ZERO; 
        }
        // ���ё�����Null�ł͂Ȃ��ꍇ        
        if (!XxcmnUtility.isBlankOrNull(investedQty)) 
        {
          Number mtlDtlId    = (Number)row.getAttribute("MaterialDetailId"); // ���Y�����ڍ�ID   
          Number mtlAddonId  = (Number)row.getAttribute("MtlDetailAddonId"); // ���Y�����ڍ׃A�h�I��ID   
          Number transId     = (Number)row.getAttribute("TransId");          // �g�����U�N�V����ID
          Number itemId      = (Number)row.getAttribute("ItemId");           // �i��ID
          String itemType    = (String)row.getAttribute("ItemClassCode");    // �i�ڃ^�C�v
          Number lotId       = (Number)row.getAttribute("LotId");            // ���b�gID
          Number movLotDtlId = (Number)row.getAttribute("MovLotDtlId");      // �ړ����b�g�ڍ׏ڍ�ID   
          String xmldActualQuantity = (String)row.getAttribute("XmldActualQuantity"); // �ړ����b�g�ڍ׎��ѐ���   
          String itemNo      = (String)row.getAttribute("ItemNo");           // �i�ڃR�[�h
          String lotNo       = (String)row.getAttribute("LotNo");            // ���b�gNo
          // ������ݒ肵�܂��B
          HashMap params = new HashMap();
          params.put("batchId",     batchId);
          params.put("mtlDtlId",    mtlDtlId);
          params.put("transId",     transId);
          params.put("movLotDtlId", movLotDtlId);
          params.put("itemId",      itemId);
          params.put("itemNo",      itemNo);
          params.put("lotId",       lotId);
          params.put("lotNo",       lotNo);
          params.put("xmldActualQuantity",   xmldActualQuantity);
          params.put("location",    location);
          params.put("productDate", productDate);
           
          // �w�����ʂ�0�ȊO�ŁA���ѐ��ʁA�ߓ����ʂ�0�����͂��ꂽ�ꍇ
          if (XxcmnUtility.isBlankOrNull(instructionsQty)
           && XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)) 
          {
            /****************************************
             * �폜����
             *****************************************/
            //PL/SQL�̐ݒ���s���܂�
            CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                        delSb.toString(),
                                        OADBTransaction.DEFAULT);
            try
            {
              //PL/SQL�����s���܂�
              int x = 1;
              cstmt.setInt(x++, XxcmnUtility.intValue(mtlAddonId));

              // ���Y�����ڍ׃A�h�I���̍s���X�V���܂��B
              cstmt.execute();
              actualQty = XxcmnConstants.STRING_ZERO;
              params.put("actualQty",   actualQty);
              exeFlag = true;

              // �����폜API�����s���܂��B
              XxwipUtility.deleteLineAllocation(
                getOADBTransaction(),
                params,
                XxwipConstants.LINE_TYPE_INVEST);
              // �ړ����b�g�ڍׂւ̏����ݏ������s���܂��B
              XxwipUtility.movLotExecute(
                getOADBTransaction(),
                params);
            } catch (SQLException s) 
            {
              // ���[���o�b�N
              XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
              XxcmnUtility.writeLog(getOADBTransaction(),
                                    XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                // ���[���o�b�N
                XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
                XxcmnUtility.writeLog(getOADBTransaction(),
                                      XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                                      s.toString(),
                                      6);
                throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                      XxcmnConstants.XXCMN10123);
              } 
            }
          // ���ʂ��ύX���ꂽ�ꍇ
          }else if (!XxcmnUtility.chkCompareNumeric(3, investedQty, baseInvestedQty)
                 || !XxcmnUtility.chkCompareNumeric(3, returnQty,   baseReturnQty)
                 || !XxcmnUtility.chkCompareNumeric(3, mtlProdQty,  baseMtlProdQty)
                 || !XxcmnUtility.chkCompareNumeric(3, mtlMfgQty,   baseMtlMfgQty)) 
          {
            /****************************************
             * �X�V����
             *****************************************/
            //PL/SQL�̐ݒ���s���܂�
            CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                        updSb.toString(),
                                        OADBTransaction.DEFAULT);
            try
            {
              //PL/SQL�����s���܂�
              int x = 1;
              cstmt.setString(x++, investedQty);
              cstmt.setString(x++, returnQty);
              cstmt.setString(x++, mtlProdQty);
              cstmt.setString(x++, mtlMfgQty);
              cstmt.setInt(x++, XxcmnUtility.intValue(mtlAddonId));
              cstmt.registerOutParameter(x++, Types.NUMERIC); 
              cstmt.setString(x++, investedQty);
              cstmt.setString(x++, returnQty);

              // ���Y�����ڍ׃A�h�I���̍s���X�V���܂��B
              cstmt.execute();
              actualQty = cstmt.getString(6);
              params.put("actualQty",    actualQty);
              // �w��������Null�ȊO�̏ꍇ�A�폜�ł͖����X�V�B
              if (!XxcmnUtility.isBlankOrNull(instructionsQty)
               &&  XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
               &&  XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)) 
              {
                params.put("completedInd", XxcmnConstants.STRING_ZERO);
                params.put("actualQty",    instructionsQty.replaceAll(",", ""));
              }
              exeFlag = true;

              // �����X�VAPI�����s���܂��B
              XxwipUtility.updateLineAllocation(
                getOADBTransaction(),
                params,
                XxwipConstants.LINE_TYPE_INVEST);
              // �ړ����b�g�ڍׂւ̏����ݏ������s���܂��B
              XxwipUtility.movLotExecute(
                getOADBTransaction(),
                params);
            } catch (SQLException s) 
            {
              // ���[���o�b�N
              XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
              XxcmnUtility.writeLog(getOADBTransaction(),
                                    XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                // ���[���o�b�N
                XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
                XxcmnUtility.writeLog(getOADBTransaction(),
                                      XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                                      s.toString(),
                                      6);
                throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                      XxcmnConstants.XXCMN10123);
              } 
            }
          }
        }
      }        
    }
    return exeFlag;
  } // lineAllocation

  /***************************************************************************
   * �R�~�b�g�������s�����\�b�h�ł��B
   * @param batchId - �o�b�`ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doCommit(
    String batchId,
    String mtlDtlId,
    String tabType
  ) throws OAException
  {
    // �R�~�b�g
    getOADBTransaction().commit();
    // �o�b�`�w�b�_���VO�擾
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    // ���������s���܂��B
    xbhvo.initQuery(batchId);
    OARow row = (OARow)xbhvo.first();
    // ���O�敪���擾���A���Ђ̏ꍇ�A�ϑ����H�P���A���̑����z�𖳌��ɂ��܂��B
    String inOutType = (String)row.getAttribute("InOutType");
    if (XxcmnUtility.isEquals(inOutType, XxwipConstants.IN_OUT_TYPE_ITAKU)) 
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
    }
    // �Č���
    doChange(mtlDtlId, tabType);
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

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxwip.xxwip200002j.server", "XxwipInvestActualAMLocal");
  }

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
   * Container's getter for XxwipInvestLotVO1
   */
  public XxwipInvestLotVOImpl getXxwipInvestLotVO1()
  {
    return (XxwipInvestLotVOImpl)findViewObject("XxwipInvestLotVO1");
  }

  /**
   * 
   * Container's getter for XxwipInvestActualPVO1
   */
  public XxwipInvestActualPVOImpl getXxwipInvestActualPVO1()
  {
    return (XxwipInvestActualPVOImpl)findViewObject("XxwipInvestActualPVO1");
  }

  /**
   * 
   * Container's getter for XxwipReInvestLotVO1
   */
  public XxwipReInvestLotVOImpl getXxwipReInvestLotVO1()
  {
    return (XxwipReInvestLotVOImpl)findViewObject("XxwipReInvestLotVO1");
  }

  /**
   * 
   * Container's getter for XxwipItemChoiceInvestVO1
   */
  public XxwipItemChoiceInvestVOImpl getXxwipItemChoiceInvestVO1()
  {
    return (XxwipItemChoiceInvestVOImpl)findViewObject("XxwipItemChoiceInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipItemChoiceReInvestVO1
   */
  public XxwipItemChoiceReInvestVOImpl getXxwipItemChoiceReInvestVO1()
  {
    return (XxwipItemChoiceReInvestVOImpl)findViewObject("XxwipItemChoiceReInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchHeaderVO1
   */
  public XxwipBatchHeaderVOImpl getXxwipBatchHeaderVO1()
  {
    return (XxwipBatchHeaderVOImpl)findViewObject("XxwipBatchHeaderVO1");
  }
}