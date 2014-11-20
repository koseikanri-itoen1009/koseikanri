/*============================================================================
* �t�@�C���� : XxpoInspectLotSearchAMImpl
* �T�v����   : �������b�g��񌟍��E�o�^�A�v���P�[�V�������W���[��
* �o�[�W���� : 1.4
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  �˒J�c ���    �V�K�쐬
* 2008-05-09 1.1  �F�{ �a�Y      �����ύX�v��#28,41,43�Ή�
* 2008-12-24 1.2  ��r���       �{�ԏ�Q#743�Ή�
* 2009-02-06 1.3  �ɓ��ЂƂ�     �{�ԏ�Q#1147�Ή�
* 2009-02-13 1.4  �ɓ��ЂƂ�     �{�ԏ�Q#1147�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.xxpo370002j.server.XxpoLotsMstRegVOImpl;
import itoen.oracle.apps.xxpo.xxpo370002j.server.XxwipQtInspectionSummaryVOImpl;

import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import java.text.SimpleDateFormat;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * �������b�g��񌟍��E�o�^��ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE SCS
 * @version 1.4
 ***************************************************************************
 */
public class XxpoInspectLotSearchAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoInspectLotSearchAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo370001j.server",
                 "XxpoInspectLotSearchAMLocal");
  }

  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void initialize()
  {
    // �\���pVO�̎擾
    OAViewObject dispVo = (OAViewObject)getXxpoDispInspectLotSummaryVO1();
    // �i�[�s��`
    Row dispRow = null;
    // �������擾���\�b�h�̌Ăяo��
    // ���[�U�[���擾 
    HashMap retHashMap = getUserData();

    if (dispVo.getFetchedRowCount() == 0)
    {
      dispVo.setMaxFetchSize(0);
      // �����A����於���i�[
      dispRow = dispVo.createRow();      
      dispRow.setAttribute(
        "SearchVendorNo", (String)retHashMap.get("VendorCode"));

      if (!XxcmnUtility.isBlankOrNull(retHashMap.get("VendorId")))
      {
        try 
        {
          dispRow.setAttribute("SearchVendorId",
            new Number(retHashMap.get("VendorId")));
        } catch (SQLException s)
        {
          // �z��O�G���[
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);        
        }       
      }
      dispRow.setAttribute(
        "SearchVendorName", (String)retHashMap.get("VendorName"));
      dispVo.insertRow(dispRow);        
    }
    // 1�s�ڎ擾
    dispRow = (OARow)dispVo.first();
  }

  /***************************************************************************
   * ���[�U�[�����擾���郁�\�b�h�ł��B
   * @return ���[�U�[���
   ***************************************************************************
   */
  public HashMap getUserData()
  {
    // ���[�U�[���擾 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // �g�����U�N�V����
                          );
    return retHashMap;
  }

  /***************************************************************************
   * �����������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doSearch()
  {
    // �������b�g��񌟍�VO�̎擾
    OAViewObject searchVo = (OAViewObject)getXxpoInspectLotSummaryVO1();
    OAViewObject dispVo = (OAViewObject)getXxpoDispInspectLotSummaryVO1();
    Row row = dispVo.getCurrentRow();
    // ��������
    String vendorCode = (String)row.getAttribute("SearchVendorNo");
    String vendorName = (String)row.getAttribute("SearchVendorName");
    String itemCode   = (String)row.getAttribute("SearchItemNo");
    String itemName   = (String)row.getAttribute("SearchItemShortName");
// mod start 1.1
//    oracle.jbo.domain.Number itemId
//            = (oracle.jbo.domain.Number)row.getAttribute("SearchItemId");
    Number itemId = (Number)row.getAttribute("SearchItemId");
// mod end 1.1
    String  lotNo     = (String)row.getAttribute("SearchLotNo");
    String  productFactory
            = (String)row.getAttribute("SearchAttribute20");
    String productLotNo = (String)row.getAttribute("SearchAttribute21");
// mod start 1.1
//    oracle.jbo.domain.Date  productDateFrom
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchAttribute1From");
//    oracle.jbo.domain.Date productDateTo
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchAttribute1To");
//    oracle.jbo.domain.Date creationDateFrom
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchCreationDateFrom");
//    oracle.jbo.domain.Date creationDateTo
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchCreationDateTo");
//    oracle.jbo.domain.Number qtInspectReqNo
//            = (oracle.jbo.domain.Number)row.getAttribute("SearchQtInspectReqNo");

    Date  productDateFrom = (Date)row.getAttribute("SearchAttribute1From");
    Date productDateTo = (Date)row.getAttribute("SearchAttribute1To");
    Date creationDateFrom = (Date)row.getAttribute("SearchCreationDateFrom");
    Date creationDateTo = (Date)row.getAttribute("SearchCreationDateTo");
    Number qtInspectReqNo = (Number)row.getAttribute("SearchQtInspectReqNo");
// mod end 1.1

    // �p�����[�^HashMap�֌����������i�[
    HashMap searchParams = new HashMap();

    searchParams.put("vendorCode",       vendorCode);
    searchParams.put("vendorName",       vendorName);
    searchParams.put("itemCode",         itemCode);
    searchParams.put("itemName",         itemName);
    searchParams.put("itemId",           itemId);
    searchParams.put("lotNo",            lotNo);
    searchParams.put("productFactory",   productFactory);
    searchParams.put("productLotNo",     productLotNo);
    searchParams.put("productDateFrom",  productDateFrom);
    searchParams.put("productDateTo",    productDateTo);
    searchParams.put("creationDateFrom", creationDateFrom);
    searchParams.put("creationDateTo",   creationDateTo);
    searchParams.put("qtInspectReqNo",   qtInspectReqNo);

    // ****************************** //
    // *          �������s           * //
    // ****************************** //
    // �����̐ݒ�
    Serializable params[] = { searchParams };
    // �����̃f�[�^�^��ݒ�
    Class[] paramsType = { HashMap.class };
    searchVo.invokeMethod("initQuery", params, paramsType);
  }
  /***************************************************************************
   * �K�{���ڂ̓��̓`�F�b�N���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void searchInputCheck()
  {
    // �ϐ���`
    OAViewObject vo = null;
    OARow row = null;
    String checkVendorCode = null;

    // �������擾
    vo = (OAViewObject)getXxpoDispInspectLotSummaryVO1();
    row = (OARow)vo.getCurrentRow();
    checkVendorCode = (String)row.getAttribute("SearchVendorNo");

    // ����悪Null�̏ꍇ�AOAAttrValException���X���[
    if (XxcmnUtility.isBlankOrNull(checkVendorCode))
    {
      throw new OAAttrValException(
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "SearchVendorNo",
        row.getAttribute("SearchVendorNo"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002);
    }
  }
  /***************************************************************************
   * �������b�g���o�^��ʂ̏����ݒ菈�����s�����\�b�h�ł��B
   * @param lotId ���b�gID
   * @return �]�ƈ����
   ***************************************************************************
   */
  public HashMap initQuery(Number lotId)
  {
    // ���[�U�[���擾 
    HashMap retHashMap = getUserData();    
    
    // VO�̎擾
// 2009-02-06 H.Itou Mod Start
//    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    XxpoLotsMstRegVOImpl registVo = getXxpoLotsMstRegVO1();
// 2009-02-06 H.Itou Mod End
// mod start 1.1
//    OAViewObject inspectVo = (OAViewObject)getXxwipQtInspectionSummaryVO1();
    XxwipQtInspectionSummaryVOImpl inspectVo = getXxwipQtInspectionSummaryVO1();
// mod end 1.1
    // ���b�gID��Null�̏ꍇ�F�V�K
    if (XxcmnUtility.isBlankOrNull(lotId))
    {
// mod start 1.1
//      if (registVo.getFetchedRowCount() == 0)
//      {
//        registVo.setMaxFetchSize(0);
//      }
//      // �V�K�s(�i�[�p)���쐬����B
//      Row registRow = registVo.createRow();
//      registRow.setAttribute("Attribute8", retHashMap.get("VendorCode"));
//      registRow.setAttribute("VendorName", retHashMap.get("VendorName"));
//      registVo.insertRow(registRow);
      if (!registVo.isPreparedForExecution())
      {
        registVo.setWhereClauseParam(0,null);
        registVo.executeQuery();
        registVo.insertRow(registVo.createRow());
        // 1�s�ڂ��擾
        OARow registRow = (OARow)registVo.first();
        // �L�[�ɒl���Z�b�g
        registRow.setNewRowState(Row.STATUS_INITIALIZED);
        registRow.setAttribute("LotId", new Number(-1));
        registRow.setAttribute("Attribute8", retHashMap.get("VendorCode"));
        registRow.setAttribute("VendorName", retHashMap.get("VendorName"));
      }
// mod end 1.1

// mod start 1.1
//      if (inspectVo.getFetchedRowCount() == 0)
//      {
//        inspectVo.setMaxFetchSize(0);
//      }
//      // �V�K�s���쐬����
//      Row inspectRow = inspectVo.createRow();
//      inspectVo.insertRow(inspectRow);
      if (!inspectVo.isPreparedForExecution())
      {
        inspectVo.setWhereClauseParam(0,null);
        inspectVo.executeQuery();
        inspectVo.insertRow(inspectVo.createRow());
        // 1�s�ڂ��擾
        OARow inspectRow = (OARow)inspectVo.first();
        // �L�[�ɒl���Z�b�g
        inspectRow.setNewRowState(Row.STATUS_INITIALIZED);
      }

// mod end 1.1
    // ���b�gID��Null����Ȃ��ꍇ�F�X�V
    } else 
    {
// 2009-02-06 H.Itou Mod Start
      // �p�����[�^�̐ݒ�
//      Serializable[] params = { new Number(lotId) };
//      Class[] paramTypes = { Number.class };
//
//      // ����������(OPM���b�g�}�X�^�o�^VO)
//      registVo.setMaxFetchSize(1);
//
//      registVo.invokeMethod("initQuery", params, paramTypes);

      registVo.initQuery(new Number(lotId));

// 2009-02-06 H.Itou Mod End

      if (registVo.getRowCount() == 0)
      {
        // �z��O�G���[
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
      }
      // �s���擾����B
// 2009-02-06 H.Itou Mod Start
//      Row registRow = registVo.first();
      OARow registRow = (OARow)registVo.first();
// 2009-02-06 H.Itou Mod End
      // �����˗�No�̎擾
      String insReqNo = (String)registRow.getAttribute("Attribute22");
// mod start 1.1
/*
      if (!XxcmnUtility.isBlankOrNull(insReqNo))
      {
        try{
          // �p�����[�^�̐ݒ�
          Serializable[] params2 = { new Number(insReqNo) };
          Class[] paramTypes2 = { Number.class };
          // ����������(�����˗����A�h�I��VO)
          inspectVo.setMaxFetchSize(1);
          inspectVo.invokeMethod("initQuery", params2, paramTypes2);
        } catch (SQLException ex)
        {
          // �z��O�G���[
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
        }
      }
*/
      inspectVo.initQuery(insReqNo);
// mod end 1.1
    }
    return retHashMap;
  }

  /***************************************************************************
   * �u�K�p�v�{�^���������̕K�{�`�F�b�N���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void inputCheck()
  {
    // VO�̎擾
    OAViewObject vo = (OAViewObject)getXxpoLotsMstRegVO1();
    // ���ݍs�̎擾
    Row row = vo.getCurrentRow();

    // ��O�o�͗p���X�g�̒�`
    List exceptions = new ArrayList();

    // ����悪������
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("Attribute8")))
    {
      // ����於��Null�ɐݒ�
      row.setAttribute("VendorName", null);

      exceptions.add( new OAAttrValException(         
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "Attribute8",
        row.getAttribute("Attribute8"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002));
    }
    // �i�ڂ�������
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("ItemNo")))
    {
      // �i�ږ��E�i��ID��Null�ɐݒ�
      row.setAttribute("ItemShortName", null);
      row.setAttribute("ItemId", null);

      exceptions.add( new OAAttrValException(         
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "ItemNo",
        row.getAttribute("ItemNo"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002));
    }
    // ������/�d������������
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("Attribute1")))
    {
      exceptions.add( new OAAttrValException(         
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "Attribute1",
        row.getAttribute("Attribute1"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002));
    }
    // ��O�̏o��
    OAException.raiseBundledOAException(exceptions);

// 2009-02-06 H.Itou Mod Start �{�ԏ�Q#1147
    // �i�ږ��擾�G���[�`�F�b�N
    Date productedDate = (Date)row.getAttribute("Attribute1");
    Number itemId = (Number)row.getAttribute("ItemId");
    String itemCode = (String)row.getAttribute("ItemNo");

    XxpoUtility.getUseByDate(
                         getOADBTransaction(),  // �g�����U�N�V����
                         itemId,                // �i��ID
                         productedDate,         // ������
                         itemCode
                         );
// 2009-02-06 H.Itou Mod End

  }

  /***************************************************************************
   * �ܖ��������擾���郁�\�b�h�ł��B
   ***************************************************************************
   */
  public void getBestBeforeDate()
  {
    // �ϐ�
    String txtBestBeforeDate = null;
    String txtproductedDate = null;
// mod start 1.1
//    oracle.jbo.domain.Date bestBeforeDate = null;
    Date bestBeforeDate = null;
// mod end 1.1    
    // �������b�g���:�o�^VO�擾
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 1�s�ڂ��擾
    Row registRow = registVo.first();
    // ������/�d�������擾
// mod start 1.1
//    oracle.jbo.domain.Date productedDate 
//    = (oracle.jbo.domain.Date)registRow.getAttribute("Attribute1");
    Date productedDate = (Date)registRow.getAttribute("Attribute1");
// mod end 1.1
    Number itemId = (Number)registRow.getAttribute("ItemId");
// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147
    String itemCode = (String)registRow.getAttribute("ItemNo");
// 2009-02-06 H.Itou Add End
// 2009-02-06 H.Itou Del Start �{�ԏ�Q#1147
//    // ������/�d�������ݒ肳��Ă��Ȃ��ꍇ
//    if (XxcmnUtility.isBlankOrNull(productedDate))
//    {
//      // �ܖ�������Null��ݒ�
//      registRow.setAttribute("Attribute3", null);
//
//    // �������ݒ肳��Ă��Ȃ��ꍇ
//    } else if (XxcmnUtility.isBlankOrNull(itemId))
//    {
//      // �ܖ������ɐ�����/�d������ݒ�
//      registRow.setAttribute("Attribute3", productedDate);
//
//    // �ܖ������擾����
//    } else
//    {
// 2009-02-06 H.Itou Del End
      bestBeforeDate = XxpoUtility.getUseByDate(
                         getOADBTransaction(),  // �g�����U�N�V����
                         itemId,                // �i��ID
                         productedDate,         // ������
// 2009-02-06 H.Itou Mod Start �{�ԏ�Q#1147
//                         "dummy"               // �ܖ�����(���g�p)
                         itemCode
// 2009-02-06 H.Itou Mod End
                         );

      // �ܖ��������������b�g���:�o�^VO�ɃZ�b�g
      registRow.setAttribute("Attribute3", bestBeforeDate);
// 2009-02-06 H.Itou Del Start �{�ԏ�Q#1147
//    }
// 2009-02-06 H.Itou Del End
  }

  /***************************************************************************
   * �������b�g���A�y�ѕi�������˗����̍쐬���s�������ł��B
   * @return List ���b�gID�ƌ����˗�No.���i�[
   * @throws OAException OA��O
   ***************************************************************************
   */
  public List doInsert() throws OAException
  {
    // �ϐ���`
    Number lotId = null;
    String lotNo = null;
    Number itemId = null;
    String itemCode = null;
    String testCode = null;
    int qtInspectReqNo = 0;

    // �������ʃ��b�Z�[�W�i�[�p���X�g�̒�`
    List exptArray = new ArrayList();
    // �߂�l�p���X�g�̒�`
    List retArray = new ArrayList();

    // �g�����U�N�V�����̎擾
    OADBTransaction trans = getOADBTransaction();

    // �Z�[�u�|�C���g�̐ݒ�
    trans.executeCommand("SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);

    // VO�̎擾
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // ���ݍs�̎擾
    Row registRow = registVo.getCurrentRow();

    // ��ʍ��ڂ̎擾
    itemId = (Number)registRow.getAttribute("ItemId");
    itemCode = (String)registRow.getAttribute("ItemNo");

    // �����L���敪
    testCode = getTestCode(itemCode);

    // ************************* //
    // *  ���b�g�ԍ������̔�API  * //
    // ************************* //
    lotNo = generateLotNo(trans, itemId, itemCode);
    try
    {
      // ************************* //
      // *      ���b�g�쐬API     * //
      // ************************* //
      lotId = callCreateLot(trans, lotNo, testCode);

      // �߂�l���X�g�Ƀ��b�gID��ǉ�
      retArray.add(lotId);

    } catch(OAException createLotExpt)
    {
      // ���[���o�b�N�̎��s
      trans.executeCommand(
        "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
      // Catch������O���X���[����
      throw createLotExpt;
    }

    // �i�ڂɕR�Â������L���敪���u1(�L)�v�̏ꍇ
    if ("1".equals(testCode))
    {
      try
      {
        // ************************* //
        // * �i�������˗����쐬API * //
        // ************************* //
        qtInspectReqNo = callMakeQtInspection(trans,
                                              lotId,
                                              itemId,
                                              0,
                                              "insert"); 
        // �߂�l���X�g�ɕi�������˗�No.��ǉ�
        retArray.add(new Number(qtInspectReqNo));

      } catch(OAException makeQtInspectExpt)
      {
        // ���[���o�b�N�̎��s
        trans.executeCommand(
          "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);

// 20080321 del yoshimoto Start
/*
        // ���b�Z�[�W�����X�g�ɒǉ�
        // ���b�g���쐬�������b�Z�[�W
        MessageToken[] tokens = { new MessageToken(
          "PROCESS", XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };

        exptArray.add(new OAException(
                        XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN05001,
                        tokens,
                        OAException.ERROR,
                        null));
*/
// 20080321 del yoshimoto End

        // �i�������˗����쐬���s���b�Z�[�W
        exptArray.add(makeQtInspectExpt);

        // ��O�̏o��
        OAException.raiseBundledOAException(exptArray);
      }
    }
    // �R�~�b�g
    trans.commit();
    return retArray;
  }

  /***************************************************************************
   * �������b�g���A�y�ѕi�������˗����̍X�V���s�������ł��B
   * @throws OAException
   ***************************************************************************
   */
  public List doUpdate() throws OAException
  {
    // �ϐ���`
    Number lotId = null;
    String lotNo = null;
    Number itemId = null;
    String itemCode = null;
    String testCode = null;
    int qtInspectReqNo = 0;
    
    // �������ʃ��b�Z�[�W�i�[�p���X�g�̒�`
    List exptArray = new ArrayList();
    // ���t/�����t�H�[�}�b�g�T�u�N���X��`
    SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy/MM/dd");
    
    // VO�̎擾
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // ���ݍs�̎擾
    Row registRow = registVo.getCurrentRow();
    
    // ��ʍ��ڂ̎擾
    lotId = (Number)registRow.getAttribute("LotId");
    lotNo = (String)registRow.getAttribute("LotNo");
    itemId = (Number)registRow.getAttribute("ItemId");
    itemCode = (String)registRow.getAttribute("ItemNo");
    if (!XxcmnUtility.isBlankOrNull(registRow.getAttribute("Attribute22")))
    {
      qtInspectReqNo =
        Integer.parseInt((String)registRow.getAttribute("Attribute22"));      
    }

    // �g�����U�N�V�����̎擾
    OADBTransaction trans = getOADBTransaction();

    // �Z�[�u�|�C���g�̐ݒ�
    trans.executeCommand("SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);

    // �����L���敪
    testCode = getTestCode(itemCode);

    try 
    {
      // ���b�N����
      getLotLock(trans, lotId, itemId);
      // �r������
      chkLotEexclusiveControl(trans, lotId, itemId);
      
      // ************************* //
      // *      ���b�g�X�VAPI     * //
      // ************************* //
      callUpdateLot(trans,
                    lotNo,
                    lotId,
                    itemId,
                    testCode);
      
    } catch (OAException updateLotExpt)
    {
      // ���[���o�b�N�A�R�~�b�g(���b�N�̉���)�̎��s
      trans.executeCommand(
        "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
      trans.commit();
      // �ُ�I�������ꍇ�ACatch������O���X���[����
      throw updateLotExpt;
    }

    // ������/�d�������擾
    Date attribute1Date =
      (Date)registRow.getAttribute("Attribute1");
    String txtAttribute1Date =
      (String)sdf1.format(attribute1Date.dateValue());
    String preAttribute1 =
      (String)registRow.getAttribute("PreAttribute1");

    // ������/�d�������ύX���ꂽ�ꍇ
    if (!txtAttribute1Date.equals(preAttribute1))
    {        
      // �i�ڂɕR�Â������L���敪���u1(�L)�v�̏ꍇ
      if ("1".equals(testCode))
      {
        try
        {
          // ���b�N����
          getInspectLock(trans, qtInspectReqNo, lotId, itemId);
          // �r������
          chkInspectEexclusiveControl(trans, qtInspectReqNo, lotId, itemId);
      
          // ************************* //
          // * �i�������˗����X�VAPI * //
          // ************************* //        
          qtInspectReqNo = callMakeQtInspection(trans,
                                                lotId,
                                                itemId,
                                                qtInspectReqNo,
                                                "update");              
        } catch(OAException makeQtInspectExpt)
        {
          // ���[���o�b�N�A�R�~�b�g(���b�N�̉���)�̎��s
          trans.executeCommand(
            "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
          trans.commit();
          
// 20080321 del yoshimoto Start
/*
          // ���b�Z�[�W�̒ǉ�
          // ���b�g���X�V�������b�Z�[�W�̒ǉ�
          MessageToken[] tokens = 
            { new MessageToken("PROCESS",
                               XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };

          exptArray.add(new OAException(
                          XxcmnConstants.APPL_XXCMN,
                          XxcmnConstants.XXCMN05001,
                          tokens,
                          OAException.ERROR,
                          null));
*/
// 20080321 del yoshimoto End

          // �i�������˗����X�V���s���b�Z�[�W           
          exptArray.add(makeQtInspectExpt);

          // ��O�̏o��
          OAException.raiseBundledOAException(exptArray);
        }
        // ����I�������ꍇ�A���b�Z�[�W�����X�g�Ɋi�[
        // ���b�g���X�V�������b�Z�[�W
        MessageToken[] tokens = {
          new MessageToken("PROCESS",
                           XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };

        exptArray.add(new OAException(
                        XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN05001,
                        tokens,
                        OAException.INFORMATION,
                        null));

        // �i�������˗����X�V�������b�Z�[�W
        MessageToken[] tokens2 = { new MessageToken(
          "PROCESS", XxpoConstants.TOKEN_NAME_UPDATE_QT_INSPECTION) };

        exptArray.add(new OAException(
                        XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN05001,
                        tokens2,
                        OAException.INFORMATION,
                        null));
        // �R�~�b�g
        trans.commit();

        // ���b�Z�[�W�̏o��
        return exptArray;
      }
    }
    // ���b�g���X�V�������b�Z�[�W
    MessageToken[] tokens = {
      new MessageToken("PROCESS", XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };

    exptArray.add(new OAException(
                    XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN05001,
                    tokens,
                    OAException.INFORMATION,
                    null));
    // �R�~�b�g
    trans.commit();
    // ���b�Z�[�W�̏o��
    return exptArray;
  }

  /***************************************************************************
   * �i�ڂɕR�Â������L���敪���擾���܂��B
   * @param itemCode �i�ڃR�[�h
   * @return testCode �����L���敪
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String getTestCode(String itemCode) throws OAException
  {
    // �ϐ���`
    String testCode = null;
    CallableStatement cstmt = null;
    String apiName = "getTestCode";

    // �g�����U�N�V�����̎擾
    OADBTransaction trans = getOADBTransaction();

    // SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT ximv.test_code ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxcmn_item_mst_v ximv ");
    sb.append("  WHERE  ximv.item_no = :2; ");
    sb.append("END;");

    // SQL�̐ݒ�
    cstmt = trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      cstmt.registerOutParameter(1, Types.VARCHAR);
      cstmt.setString(2, itemCode);

      // SQL�̎��s
      cstmt.execute();

      // �����L���敪�̎擾
      testCode = cstmt.getString(1);

    } catch (SQLException expt)
    {
      // writeLog
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // �z��O�G���[
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();
        } catch (SQLException expt2)
        {
          // writeLog
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN10123);
        }
      }
    }
    return testCode;
  }

  /***************************************************************************
   * ���b�g�쐬API���Ăяo���܂��B
   * @param trans �g�����U�N�V����
   * @param lotNo ���b�gNo
   * @param testCode �����L���敪
   * @return lotId ���b�gID
   * @throws OAException OA��O
   ***************************************************************************
   */
  public Number callCreateLot(OADBTransaction trans,
                              String lotNo,
                              String testCode) throws OAException
  {
    // �ϐ���`
    String itemCode = null;
    Number itemId = null;
    String attribute1 = null;
    String attribute3 = null;
    String attribute8 = null;
    String attribute12 = null;
    String attribute14 = null;
    String attribute15 = null;
    String attribute18 = null;
    String attribute20 = null;
    String attribute21 = null;
    String attribute23 = null;
    String attribute24 = null;
    
    String retStatus = null;
    Number msgCount = null;
    String msgData = null;
    Number lotId = null;

    String apiName = "callCreateLot";
    
    // ���t/�����t�H�[�}�b�g�T�u�N���X��`
    SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy/MM/dd");

    // VO�̎擾
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // ���ݍs�̎擾
    Row registRow = registVo.getCurrentRow();

    // Attribute3�̎擾
    java.sql.Date attr3 = XxcmnUtility.dateValue(
        (Date)registRow.getAttribute("Attribute3"));

    // ���͍��ڂ��擾
    itemCode = (String)registRow.getAttribute("ItemNo");
    attribute1 = sdf1.format(XxcmnUtility.dateValue(
      (Date)registRow.getAttribute("Attribute1")));
    if (!XxcmnUtility.isBlankOrNull(attr3))
    {
      // Null�łȂ���΃t�H�[�}�b�g����B
      attribute3 = sdf1.format(attr3); 
    }
    attribute8 = (String)registRow.getAttribute("Attribute8");
    attribute12 = (String)registRow.getAttribute("Attribute12");
    attribute14 = (String)registRow.getAttribute("Attribute14");
    attribute15 = (String)registRow.getAttribute("Attribute15");
    attribute18 = (String)registRow.getAttribute("Attribute18");
    attribute20 = (String)registRow.getAttribute("Attribute20");
    attribute21 = (String)registRow.getAttribute("Attribute21");
    // �쐬�敪�ɂ͏�Ɂu1�v��ݒ�    
    attribute24 = "1";

    // �����L���敪���u1(�L)�v�̏ꍇ�A���b�g�X�e�[�^�X�Ɂu10(������)�v��ݒ�
    if ("1".equals(testCode))
    {
      attribute23 = "10";
    // �����L���敪���u0(��)�v�̏ꍇ�A���b�g�X�e�[�^�X�Ɂu50(���i)�v��ݒ�
    } else if ("0".equals(testCode))
    {
      attribute23 = "50";
    }

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE");
    sb.append("  lr_create_lot         GMIGAPI.lot_rec_typ; ");
    sb.append("  lr_ic_lots_mst_row    ic_lots_mst%ROWTYPE; ");
    sb.append("  lr_ic_lots_cpg_row    ic_lots_cpg%ROWTYPE; ");
    sb.append("  ln_api_version_number CONSTANT NUMBER := 3.0; ");
    sb.append("  lb_setup_return_sts    BOOLEAN; ");
    sb.append("BEGIN"); 
    sb.append("  lb_setup_return_sts := GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "); 
    sb.append("  lr_create_lot.item_no      := :1; "); // �i�ڃR�[�h
    sb.append("  lr_create_lot.lot_no       := :2; "); // ���b�gNo
    sb.append("  lr_create_lot.lot_created  := TRUNC(SYSDATE); "); // �쐬��
// 2008-12-24 v.1.6 D.Nihei Add Start �{�ԏ�Q#743
    sb.append("  lr_create_lot.expaction_date := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // �ăe�X�g���t
    sb.append("  lr_create_lot.expire_date    := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // �������t
// 2008-12-24 v.1.6 D.Nihei Add End
    sb.append("  lr_create_lot.inactive_ind := 0; "); // �L��
    sb.append("  lr_create_lot.origination_type := '0'; "); // ���^�C�v
    sb.append("  lr_create_lot.attribute1   := :3; "); // ������/�d����
    sb.append("  lr_create_lot.attribute3   := :4; "); // �ܖ�����
    sb.append("  lr_create_lot.attribute8   := :5; "); // �����R�[�h
    sb.append("  lr_create_lot.attribute12  := :6; "); // �Y�n
    sb.append("  lr_create_lot.attribute14  := :7; "); // �����N�P
    sb.append("  lr_create_lot.attribute15  := :8; "); // �����N�Q
    sb.append("  lr_create_lot.attribute18  := :9; "); // �E�v
    sb.append("  lr_create_lot.attribute20  := :10; "); // �����H��
    sb.append("  lr_create_lot.attribute21  := :11; "); // �������b�g�ԍ�
    sb.append("  lr_create_lot.attribute23  := :12; "); // ���b�g�X�e�[�^�X
    sb.append("  lr_create_lot.attribute24  := :13; "); // �쐬�敪
    sb.append("  GMIPAPI.CREATE_LOT ( ");
    sb.append("    ln_api_version_number ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_VALID_LEVEL_FULL ");
    sb.append("   ,lr_create_lot ");
    sb.append("   ,lr_ic_lots_mst_row ");
    sb.append("   ,lr_ic_lots_cpg_row ");
    sb.append("   ,:14 ");
    sb.append("   ,:15 ");
    sb.append("   ,:16 ); ");
    sb.append("  :17 := lr_ic_lots_mst_row.lot_id; ");
    sb.append("END; ");

    // PL/SQL�̐ݒ�
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      // �o�C���h�ϐ��ɒl��ݒ�
      cstmt.setString(1, itemCode);
      cstmt.setString(2, lotNo);
      cstmt.setString(3, attribute1);
      cstmt.setString(4, attribute3);
      cstmt.setString(5, attribute8);
      cstmt.setString(6, attribute12);
      cstmt.setString(7, attribute14);
      cstmt.setString(8, attribute15);
      cstmt.setString(9, attribute18);
      cstmt.setString(10, attribute20);
      cstmt.setString(11, attribute21);
      cstmt.setString(12, attribute23);
      cstmt.setString(13, attribute24);
      cstmt.registerOutParameter(14, Types.VARCHAR);
      cstmt.registerOutParameter(15, Types.INTEGER);
      cstmt.registerOutParameter(16, Types.VARCHAR);
      cstmt.registerOutParameter(17, Types.INTEGER);

      // PL/SQL�̎��s
      cstmt.execute();
      // ���^�[���R�[�h�̎擾
      retStatus = cstmt.getString(14);

      // ����I���̏ꍇ
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus))
      {
        // ���b�gID���擾
        lotId = new Number(cstmt.getInt(17));

      // �ُ�I���̏ꍇ
      } else
      {
        // ���b�Z�[�W�̏o��
        MessageToken[] tokens = {
          new MessageToken("INFO_NAME", XxpoConstants.TOKEN_NAME_LOT_INFO) };
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10007,
          tokens,
          OAException.ERROR,
          null);
      }
    } catch(SQLException expt)
    {
      // writeLog
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // �z��O�G���[
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();         
        } catch (SQLException expt2)
        {
          // writeLog
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          // �z��O�G���[
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN10123);
        }
      }
    }
    // ���b�gID��Ԃ�
    return lotId;
  }

  /***************************************************************************
   * ���b�g�X�VAPI���Ăяo���܂��B
   * @param trans �g�����U�N�V����
   * @param lotNo ���b�gNo
   * @param lotId ���b�gID
   * @param itemId �i��ID
   * @param testCode �����L���敪
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void callUpdateLot(OADBTransaction trans,
                              String lotNo,
                              Number lotId,
                              Number itemId,
                              String testCode) throws OAException
  {
    // �ϐ���`
    String attribute1 = null;
    String attribute3 = null;
    String attribute12 = null;
    String attribute14 = null;
    String attribute15 = null;
    String attribute18 = null;
    String attribute20 = null;
    String attribute21 = null;
    
    String retStatus = null;
    Number msgCount = null;
    String msgData = null;

    String apiName = "callUpdateLot";

    // ���t/�����t�H�[�}�b�g�T�u�N���X��`
    SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy/MM/dd");

    // VO�̎擾
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // ���ݍs�̎擾
    Row registRow = registVo.getCurrentRow();

    // java.sql.Date�ɕϊ�����B
    java.sql.Date attr3 = XxcmnUtility.dateValue(
// mod start 1.1
//      (oracle.jbo.domain.Date)registRow.getAttribute("Attribute3"));
      (Date)registRow.getAttribute("Attribute3"));
// mod end 1.1    
    // ���͍��ڂ��擾
    attribute1 = sdf1.format(XxcmnUtility.dateValue(
// mod start 1.1
//      (oracle.jbo.domain.Date)registRow.getAttribute("Attribute1")));
      (Date)registRow.getAttribute("Attribute1")));
// mod end 1.1
    if (!XxcmnUtility.isBlankOrNull(attr3)){
      // Null�łȂ���΁AYYYY/MM/DD�Ƃ���B
      attribute3 = sdf1.format(attr3);
    }
    attribute12 = (String)registRow.getAttribute("Attribute12");
    attribute14 = (String)registRow.getAttribute("Attribute14");
    attribute15 = (String)registRow.getAttribute("Attribute15");
    attribute18 = (String)registRow.getAttribute("Attribute18");
    attribute20 = (String)registRow.getAttribute("Attribute20");
    attribute21 = (String)registRow.getAttribute("Attribute21");

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE");
    sb.append("  l_lot_rec            ic_lots_mst%ROWTYPE;");
    sb.append("  l_lot_cpg_rec        ic_lots_cpg%ROWTYPE;");
    sb.append("  ln_api_version_number CONSTANT NUMBER := 1.0; ");
    sb.append("BEGIN ");
    sb.append("  SELECT * ");
    sb.append("  INTO   l_lot_rec ");
    sb.append("  FROM   ic_lots_mst    ilm ");
    sb.append("  WHERE  ilm.lot_no     = :1 ");
    sb.append("  AND    ilm.lot_id     = :2 ");
    sb.append("  AND    ilm.item_id    = :3; ");
    sb.append("  l_lot_rec.attribute1       := :4; ");
    sb.append("  l_lot_rec.attribute3       := :5; ");
    sb.append("  l_lot_rec.attribute12      := :6; ");
    sb.append("  l_lot_rec.attribute14      := :7; ");
    sb.append("  l_lot_rec.attribute15      := :8; ");
    sb.append("  l_lot_rec.attribute18      := :9; ");
    sb.append("  l_lot_rec.attribute20      := :10; ");
    sb.append("  l_lot_rec.attribute21      := :11; ");
    sb.append("  l_lot_rec.last_updated_by  := :12; ");
    //sb.append("  l_lot_rec.last_update_date := TRUNC(SYSDATE); ");
    sb.append("  l_lot_rec.last_update_date := SYSDATE; ");     // 20080305 mod yoshimoto
    sb.append("  l_lot_cpg_rec.item_id      := l_lot_rec.item_id; ");
    sb.append("  l_lot_cpg_rec.lot_id           := l_lot_rec.lot_id; ");
    sb.append("  l_lot_cpg_rec.ic_hold_date     := TRUNC(SYSDATE); ");
    //sb.append("  l_lot_cpg_rec.last_update_date := TRUNC(SYSDATE); ");
    sb.append("  l_lot_cpg_rec.last_update_date := SYSDATE; "); // 20080305 mod yoshimoto
    sb.append("  l_lot_cpg_rec.last_updated_by  := :12; ");
    sb.append("  gmi_lotupdate_pub.update_lot ( ");
    sb.append("    ln_api_version_number ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_VALID_LEVEL_FULL ");
    sb.append("   ,:13 ");
    sb.append("   ,:14 ");
    sb.append("   ,:15 ");
    sb.append("   ,l_lot_rec ");
    sb.append("   ,l_lot_cpg_rec); ");
    sb.append("END; ");

    // PL/SQL�̐ݒ�
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      // �o�C���h�ϐ��ɒl��ݒ�
      cstmt.setString(1, lotNo);
      cstmt.setInt(2, XxcmnUtility.intValue(lotId));
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));
      cstmt.setString(4, attribute1);
      cstmt.setString(5, attribute3);
      cstmt.setString(6, attribute12);
      cstmt.setString(7, attribute14);
      cstmt.setString(8, attribute15);
      cstmt.setString(9, attribute18);
      cstmt.setString(10, attribute20);
      cstmt.setString(11, attribute21);
      cstmt.setInt(12, trans.getUserId());
      cstmt.registerOutParameter(13, Types.VARCHAR);
      cstmt.registerOutParameter(14, Types.INTEGER);
      cstmt.registerOutParameter(15, Types.VARCHAR);

      // PL/SQL�̎��s
      cstmt.execute();
      // ���^�[���R�[�h�̎擾
      retStatus = cstmt.getString(13);
      
      // �ُ�I���̏ꍇ
      if (!XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus))
      {
        // ���b�Z�[�W�̏o��
        MessageToken[] tokens =
          { new MessageToken("INFO_NAME", XxpoConstants.TOKEN_NAME_LOT_INFO),
            new MessageToken("PARAMETER", XxpoConstants.TOKEN_NAME_LOT_NO),
            new MessageToken("VALUE", lotNo) };

        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10006,
          tokens,
          OAException.ERROR,
          null);
      }
    } catch(SQLException expt)
    {
      // ���O�̎擾
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // �z��O�G���[
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();         
        } catch (SQLException expt2)
        {
          // ���O�̎擾
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          // �z��O�G���[
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * ���b�g�ԍ��̎����̔Ԃ��s�������ł��B
   * @param trans �g�����U�N�V����
   * @param itemId �i��ID
   * @param itemCode �i��
   * @return lotNo ���b�gNo
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String generateLotNo(OADBTransaction trans,
                              Number itemId,
                              String itemCode) throws OAException
  {
    // �ϐ���`
    String lotNo = null;
    String subLotNo = null;
    int retStatus = 5;  // 5�F����
    String apiName = "generateLotNo";

    // PL/SQL�쐬
    StringBuffer sb = new StringBuffer(100);

    sb.append("BEGIN ");
    sb.append("  gmi_autolot.generate_lot_number( ");
    sb.append("    :1 ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,:2 ");
    sb.append("   ,:3 ");
    sb.append("   ,:4); ");
    sb.append("END; ");

    // PL/SQL�̐ݒ�
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      // �o�C���h�ϐ��ɒl��ݒ�
      cstmt.setInt(1, XxcmnUtility.intValue(itemId));
      cstmt.registerOutParameter(2, Types.VARCHAR);
      cstmt.registerOutParameter(3, Types.VARCHAR);
      cstmt.registerOutParameter(4, Types.INTEGER);

      // PL/SQL�̎��s
      cstmt.execute();

      // �Ԃ�l��ϐ��Ɋi�[
      lotNo = cstmt.getString(2);
      subLotNo = cstmt.getString(3);
      retStatus = cstmt.getInt(4);
      // ���b�g�̎����̔ԂɎ��s�����ꍇ
      if (XxcmnUtility.isBlankOrNull(lotNo))
      {
        // ���[���o�b�N�̎��s
// mod start 1.1
//        trans.rollback();
        trans.executeCommand("ROLLBACK TO " + XxpoConstants.SAVE_POINT_XXPO370002J);
// mod end 1.1
        // �G���[���b�Z�[�W�̏o��
        MessageToken[] tokens = { new MessageToken("ITEM_NO", itemCode) };

        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10110,
          tokens,
          OAException.ERROR,
          null);
      }

    } catch(SQLException expt)
    {
      // ���[���o�b�N�̎��s
// mod start 1.1
//      trans.rollback();
      trans.executeCommand("ROLLBACK TO " + XxpoConstants.SAVE_POINT_XXPO370002J);
// mod end 1.1
      // ���O�̎擾
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // �z��O�G���[
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();
        } catch (SQLException expt2)
        {
          // ���[���o�b�N�̎��s
// mod start 1.1
//          trans.rollback();
          trans.executeCommand("ROLLBACK TO " + XxpoConstants.SAVE_POINT_XXPO370002J);
// mod end 1.1
          // ���O�̎擾
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          // �z��O�G���[
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
    // �擾�������b�gNo��Ԃ�
    return lotNo;
  }

  /***************************************************************************
   * �i�������˗����̍쐬/�X�V���s�������ł��B
   * @param trans �g�����U�N�V����
   * @param lotId ���b�gID
   * @param itemId �i��ID
   * @param pQtInspectReqNo �����˗�No
   * @param chkInsUpd �����敪(insert:�쐬�Aupdate�F�X�V)
   * @return rQtInspectReqNo �����˗�No
   * @throws OAException OA��O
   ***************************************************************************
   */
  public int callMakeQtInspection(OADBTransaction trans,
                                     Number lotId,
                                     Number itemId,
                                     int    pQtInspectReqNo,
                                     String chkInsUpd) throws OAException
  {
    // �ϐ���`
    int rQtInspectReqNo = 0;
    String retCode = null;
    String apiName = "callMakeQtInspection";

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(100);

    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.make_qt_inspection( ");
    sb.append("    '3'");
    sb.append("   ,:1");
    sb.append("   ,:2");
    sb.append("   ,:3");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,:4");
    sb.append("   ,:5");
    sb.append("   ,:6");
    sb.append("   ,:7");
    sb.append("   ,:8);");
    sb.append("END;");

    // PL/SQL�̐ݒ�
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    // �쐬�̏ꍇ
    if ("insert".equals(chkInsUpd))
    {
      try
      {
        // �o�C���h�ϐ��ɒl��ݒ�
        cstmt.setString(1, "1");
        cstmt.setInt(2, XxcmnUtility.intValue(lotId));
        cstmt.setInt(3, XxcmnUtility.intValue(itemId));
        cstmt.setNull(4, Types.INTEGER);
        cstmt.registerOutParameter(5, Types.INTEGER);
        cstmt.registerOutParameter(6, Types.VARCHAR);
        cstmt.registerOutParameter(7, Types.VARCHAR);
        cstmt.registerOutParameter(8, Types.VARCHAR);

        // PL/SQL�̎��s
        cstmt.execute();
        // ���^�[���R�[�h���擾
        retCode = cstmt.getString(7);

        // ����I��
        if ("0".equals(retCode))
        {
          // �����˗�No���擾
          rQtInspectReqNo = cstmt.getInt(5);

        // �ُ�I��
        } else
        {
          // �G���[���b�Z�[�W�o��
          MessageToken[] tokens = { 
            new MessageToken("INFO_NAME",
                             XxpoConstants.TOKEN_NAME_QT_INSPECTION_INFO) };

          throw new OAException(
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10007,
            tokens,
            OAException.ERROR,
            null);

        }
      } catch(SQLException expt)
      {
        throw OAException.wrapperException(expt);

      } finally
      {
        if (cstmt != null)
        {
          try
          {
            cstmt.close();
          
          } catch (SQLException expt2)
          {
            // ���O�̎擾
            XxcmnUtility.writeLog(
              trans,
              XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
              expt2.toString(),
              6);
            // �z��O�G���[
            throw new OAException(XxcmnConstants.APPL_XXCMN,
                                  XxcmnConstants.XXCMN10123);          }
        }
      }

    // �X�V�̏ꍇ
    } else if ("update".equals(chkInsUpd))
    {
      try
      {
        // �o�C���h�ϐ��ɒl��ݒ�
        cstmt.setString(1, "2");
        cstmt.setInt(2, XxcmnUtility.intValue(lotId));
        cstmt.setInt(3, XxcmnUtility.intValue(itemId));
        cstmt.setInt(4, pQtInspectReqNo);
        cstmt.registerOutParameter(5, Types.INTEGER);
        cstmt.registerOutParameter(6, Types.VARCHAR);
        cstmt.registerOutParameter(7, Types.VARCHAR);
        cstmt.registerOutParameter(8, Types.VARCHAR);

        // PL/SQL�̎��s
        cstmt.execute();
        // ���^�[���R�[�h���擾
        retCode = cstmt.getString(7);

        if ("0".equals(retCode))
        {
          // �����˗�No���擾
          rQtInspectReqNo = cstmt.getInt(5);

        } else
        {
          // �G���[���b�Z�[�W�o��
          MessageToken[] tokens = {
            new MessageToken(
              "INFO_NAME", XxpoConstants.TOKEN_NAME_QT_INSPECTION_INFO),
            new MessageToken(
              "PARAMETER", XxpoConstants.TOKEN_NAME_REQ_NO),
            new MessageToken(
              "VALUE", String.valueOf(pQtInspectReqNo)) };

          throw new OAException(
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10006,
            tokens,
            OAException.ERROR,
            null);
        }
      } catch(SQLException expt)
      {
        // ���O�̎擾
        XxcmnUtility.writeLog(
          trans,
          XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
          expt.toString(),
          6);
        // �z��O�G���[
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123); 

      } finally
      {
        if (cstmt != null)
        {
          try
          {
            cstmt.close();
          } catch (SQLException expt2)
          {
            // ���O�̎擾
            XxcmnUtility.writeLog(
              trans,
              XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
              expt2.toString(),
              6);
            // �z��O�G���[
            throw new OAException(XxcmnConstants.APPL_XXCMN,
                                  XxcmnConstants.XXCMN10123); 
          }
        }
      }
    }
    // �����˗�No��Ԃ�
    return rQtInspectReqNo;
  }

  /***************************************************************************
   * OPM���b�g�}�X�^�̃��b�N�������s�����\�b�h�ł��B
   * @param trans �g�����U�N�V����
   * @param lotId - ���b�gID
   * @param itemId - �i��ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getLotLock(OADBTransaction trans,
                         Number lotId,
                         Number itemId) throws OAException 
  {
    String apiName = "getLotLock";

    // SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT ilm.lot_id ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   ic_lots_mst ilm ");
    sb.append("  WHERE  ilm.lot_id  = :2 ");
    sb.append("  AND    ilm.item_id = :3 ");
    sb.append("  FOR UPDATE NOWAIT; ");
    sb.append("END; ");

    // SQL�̐ݒ�
    CallableStatement cstmt = trans.createCallableStatement(
      sb.toString(), trans.DEFAULT);

    // SQL�̎��s
    try 
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(lotId));
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));
      cstmt.execute();

    } catch (SQLException lockExpt)
    {
      // ���O�̎擾
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        lockExpt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();

        } catch (SQLException expt)
        {
          // ���O�̎擾
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * �i�������˗����A�h�I���̃��b�N�������s�����\�b�h�ł��B
   * @param trans �g�����U�N�V����
   * @param reqNo - �����˗�No.
   * @param lotId - ���b�gID
   * @param itemId - �i��ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getInspectLock(OADBTransaction trans,
                             int reqNo,
                             Number lotId,
                             Number itemId) throws OAException 
  {
    String apiName = "getInspectLock";

    // SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT xqi.qt_inspect_req_no req_no ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwip_qt_inspection xqi ");
    sb.append("        ,ic_lots_mst ilm ");
    sb.append("  WHERE  xqi.qt_inspect_req_no = :2 ");
    sb.append("  AND    xqi.qt_inspect_req_no = ilm.attribute22 ");
    sb.append("  AND    ilm.lot_id            = :3 ");
    sb.append("  AND    ilm.item_id           = :4 ");
    sb.append("  FOR UPDATE NOWAIT; ");
    sb.append("END; ");

    // SQL�̐ݒ�
    CallableStatement cstmt = trans.createCallableStatement(
      sb.toString(), trans.DEFAULT);

    // SQL�̎��s
    try 
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, reqNo);
      cstmt.setInt(3, XxcmnUtility.intValue(lotId));
      cstmt.setInt(4, XxcmnUtility.intValue(itemId));
      cstmt.execute();

    } catch (SQLException lockExpt)
    {
      // ���O�̎擾
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        lockExpt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();
        } catch (SQLException expt)
        {
          // ���O�̎擾
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * OPM���b�g�}�X�^�ɂ�����r������`�F�b�N���s�����\�b�h�ł��B
   * @param trans �g�����U�N�V����
   * @pstsm lotId ���b�gID
   * @param itemId �i��ID
   ***************************************************************************
   */
  public void chkLotEexclusiveControl(OADBTransaction trans,
                                      Number lotId,
                                      Number itemId)
  {
    // �ϐ���`
    String apiName = "chkLotEexclusiveControl";
    CallableStatement cstmt = null;

    // VO�̎擾
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    OARow registRow = (OARow)registVo.first();

    // ��ʍ��ڂ̎擾
    String lastUpdateDate =
      (String)registRow.getAttribute("IlmLastUpdateDate");

    // SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT COUNT(ilm.lot_id) cnt ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   ic_lots_mst ilm ");
    sb.append("  WHERE  ilm.lot_id = :2 ");
    sb.append("  AND    ilm.item_id = :3 ");
    sb.append("  AND    TO_CHAR(ilm.last_update_date, 'YYYY/MM/DD HH24:MI:SS') = :4 ");
    sb.append("  AND    ROWNUM     = 1; ");
    sb.append("END; ");

    // SQL�̐ݒ�
    cstmt = getOADBTransaction().createCallableStatement(
      sb.toString(),getOADBTransaction().DEFAULT);

    try
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(lotId));
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));
      cstmt.setString(4, lastUpdateDate);

      // SQL�̎��s
      cstmt.execute();      
      
      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0)
      {
        // ���b�Z�[�W�̏o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }
    } catch (SQLException expt)
    {
      // ���O�̎擾
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();

        } catch (SQLException expt2)
        {
          // ���O�̎擾
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * �i�������˗����A�h�I���ɂ�����r������`�F�b�N���s�����\�b�h�ł��B
   * @param trans �g�����U�N�V����
   * @param qtInspectReqNo �����˗�No.
   * @param lotId ���b�gID
   * @param itemId �i��ID
   ***************************************************************************
   */
  public void chkInspectEexclusiveControl(OADBTransaction trans,
                                          int qtInspectReqNo,
                                          Number lotId,
                                          Number itemId)
  {
    // �ϐ���`
    String apiName = "chkInspectEexclusiveControl";
    CallableStatement cstmt = null;

    // VO�̎擾
    OAViewObject inspectVo = (OAViewObject)getXxwipQtInspectionSummaryVO1();
    OARow inspectRow = (OARow)inspectVo.first();

    // ��ʍ��ڂ̎擾
    String lastUpdateDate =
      (String)inspectRow.getAttribute("XqiLastUpdateDate");

    // PL/SQL�̍쐬
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT COUNT(xqi.qt_inspect_req_no) cnt ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwip_qt_inspection xqi ");
    sb.append("        ,ic_lots_mst ilm ");
    sb.append("  WHERE  xqi.qt_inspect_req_no = :2 ");
    sb.append("  AND    xqi.qt_inspect_req_no = ilm.attribute22 ");
    sb.append("  AND    ilm.lot_id = :3 ");
    sb.append("  AND    ilm.item_id = :4 ");
    sb.append("  AND    TO_CHAR(xqi.last_update_date, 'YYYY/MM/DD HH24:MI:SS') = :5 ");
    sb.append("  AND    ROWNUM     = 1; ");
    sb.append("END; ");

    // PL/SQL�̐ݒ�
    cstmt = trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, qtInspectReqNo);
      cstmt.setInt(3, XxcmnUtility.intValue(lotId));
      cstmt.setInt(4, XxcmnUtility.intValue(itemId));
      cstmt.setString(5, lastUpdateDate);

      // SQL�̎��s
      cstmt.execute();

      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0)
      {
        // ���b�Z�[�W�̏o��
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }
    } catch (SQLException expt)
    {
      // ���O�̎擾
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();

        } catch (SQLException expt2)
        {
          // ���O�̎擾
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /**
   * 
   * Container's getter for XxpoInspectLotSummaryVO1
   */
  public XxpoInspectLotSummaryVOImpl getXxpoInspectLotSummaryVO1()
  {
    return (XxpoInspectLotSummaryVOImpl)findViewObject(
             "XxpoInspectLotSummaryVO1");
  }




  /**
   * 
   * Container's getter for XxpoLotsMstRegVO1
   */
  public XxpoLotsMstRegVOImpl getXxpoLotsMstRegVO1()
  {
    return (XxpoLotsMstRegVOImpl)findViewObject("XxpoLotsMstRegVO1");
  }

  /**
   * 
   * Container's getter for XxwipQtInspectionSummaryVO1
   */
  public XxwipQtInspectionSummaryVOImpl getXxwipQtInspectionSummaryVO1()
  {
    return (XxwipQtInspectionSummaryVOImpl)findViewObject("XxwipQtInspectionSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxpDispoInspectLotSummaryVO1
   */
  public XxpoDispInspectLotSummaryVOImpl getXxpoDispInspectLotSummaryVO1()
  {
    return (XxpoDispInspectLotSummaryVOImpl)findViewObject("XxpoDispInspectLotSummaryVO1");
  }



}