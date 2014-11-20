/*============================================================================
* �t�@�C���� : XxpoVendorSupplyAMImpl
* �T�v����   : �O���o�����񍐃A�v���P�[�V�������W���[��
* �o�[�W���� : 1.5
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
* 2008-05-07 1.0  �ɓ��ЂƂ�   �ύX�v���Ή�(#86,90)�A�����ύX�v���Ή�(#28,29,41)
* 2008-05-15 1.0  �ɓ��ЂƂ�   �����o�O#340_2
*                              �O�����[�U�[�̏ꍇ�A�\�����ꂽ�����R�[�h�Ō����ł��Ȃ��B
* 2008-05-21 1.0  �ɓ��ЂƂ�   �����ύX�v���Ή�(#104)
* 2008-07-11 1.1  ��r���     ST#421�Ή�
* 2008-07-22 1.2  �ɓ��ЂƂ�   �����ۑ�#32�Ή� ���Z����̏ꍇ�A�P�[�X������NULL�܂���0�̓G���[
* 2008-10-23 1.3  �ɓ��ЂƂ�   T_TE080_BPO_340 �w�E5
* 2009-02-06 1.4  �ɓ��ЂƂ�   �{�ԏ�Q#1147�Ή�
* 2009-02-18 1.5  �ɓ��ЂƂ�   �{�ԏ�Q#1096,1178�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

import java.lang.Double;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �O���o�����񍐂̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.5
 ***************************************************************************
 */
public class XxpoVendorSupplyAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoVendorSupplyAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo340001j.server", "XxpoVendorSupplyAMLocal");
  }

// ****************** ������ʗp���\�b�h **************************************

  /***************************************************************************
   * ���[�U�[�����擾���郁�\�b�h�ł��B(������ʗp)
   ***************************************************************************
   */
  public void getUserData()
  {
    // ���[�U�[���擾 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // �g�����U�N�V����
                          );

    // �O���o�������VO�擾
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();
    // 1�s�߂��擾
    OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
    // �]�ƈ��敪���Z�b�g
    vendorSupplySearchRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // �]�ƈ��敪
    // �]�ƈ��敪��2:�O���̏ꍇ�A�d��������Z�b�g
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      vendorSupplySearchRow.setAttribute("VendorCode", retHashMap.get("VendorCode")); // �����R�[�h
      vendorSupplySearchRow.setAttribute("VendorId",   retHashMap.get("VendorId"));   // �����ID
      vendorSupplySearchRow.setAttribute("VendorName", retHashMap.get("VendorName")); // �����ID
    }
  }

  /***************************************************************************
   * ���͐�����s�����\�b�h�ł��B(������ʗp)
   ***************************************************************************
   */
  public void readOnlyChanged()
  {
    // �O���o�������VO�擾
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();
    // 1�s�߂��擾
    OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
    // �f�[�^�擾
    String peopleCode       = (String)vendorSupplySearchRow.getAttribute("PeopleCode"); // �]�ƈ��R�[�h

    // �O���o��������:�o�^PVO�擾
    OAViewObject vendorSupplyPvo = getXxpoVendorSupplyPVO1();
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)vendorSupplyPvo.first();

    // 
    // �]�ƈ��R�[�h��1:�������[�U�[�̏ꍇ
    if (XxpoConstants.PEOPLE_CODE_I.equals(peopleCode)) 
    {
      readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.FALSE); // �������͉�

    // �]�ƈ��R�[�h��2:�O�����[�U�[�̏ꍇ
    } else if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode)) 
    {
      readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.TRUE);  // �������͕s��
    }
  }
  
  /***************************************************************************
   * �����������s�����\�b�h�ł��B(������ʗp)
   * @param searchParams - �����p�����[�^�pHashMap
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  )
  {
    // SQL��DATE�ɕϊ�
    java.sql.Date manufacturedDateFrom =      // ���Y��FROM
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("manufacturedDateFrom"));
    java.sql.Date manufacturedDateTo =        // ���Y��TO
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("manufacturedDateTo"));
    java.sql.Date productedDateFrom =         // ������FROM
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("productedDateFrom"));
    java.sql.Date productedDateTo =           // ������TO
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("productedDateTo"));

    // �O���o������񌟍�VO�擾
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();
    // 1�s�߂��擾
    OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
    // ���͍��ڂłȂ��ꍇ�ApageContext.getParameter("TxtVendorCode")����ł͒l���擾�ł��Ȃ����߁A�����R�[�h��VO����擾����B
    searchParams.put("vendorCode", vendorSupplySearchRow.getAttribute("VendorCode")); // �����R�[�h
    
    // �O���o�������VO�擾
    XxpoVendorSupplyVOImpl xxpoVendorSupplyVo = getXxpoVendorSupplyVO1();
    // ����
    xxpoVendorSupplyVo.initQuery(
      searchParams,         // �����p�����[�^�pHashMap
      manufacturedDateFrom, // ���Y��FROM
      manufacturedDateTo,   // ���Y��TO
      productedDateFrom,    // ������FROM
      productedDateTo);     // ������TO
    // 1�s�ڂ��擾
    OARow row = (OARow)xxpoVendorSupplyVo.first();
  }
  
  /***************************************************************************
   * �������������s�����\�b�h�ł��B(������ʗp)
   ***************************************************************************
   */
  public void initialize()
  {
    // *********************************** //
    // * �O���o������:����VO ��s�擾  * //
    // *********************************** //
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!vendorSupplySearchVo.isPreparedForExecution())
    {
      vendorSupplySearchVo.setMaxFetchSize(0);
      vendorSupplySearchVo.insertRow(vendorSupplySearchVo.createRow());
      // 1�s�ڂ��擾
      OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
      // �L�[�ɒl���Z�b�g
      vendorSupplySearchRow.setNewRowState(Row.STATUS_INITIALIZED);
      vendorSupplySearchRow.setAttribute("RowKey", new Number(1));
    }
    
    // ******************************** //
    // * �O���o������PVO ��s�擾   * //
    // ******************************** //
    OAViewObject vendorSupplyPvo = getXxpoVendorSupplyPVO1();   
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!vendorSupplyPvo.isPreparedForExecution())
    {    
      vendorSupplyPvo.setMaxFetchSize(0);
      vendorSupplyPvo.insertRow(vendorSupplyPvo.createRow());
      // 1�s�ڂ��擾
      OARow vendorSupplyPvoRow = (OARow)vendorSupplyPvo.first();
      // �L�[�ɒl���Z�b�g
      vendorSupplyPvoRow.setAttribute("RowKey", new Number(1));
    }
    
    // ******************************* //
    // *     ���[�U�[���擾        * //
    // ******************************* //
    getUserData();

    // ******************************* //
    // *      ����搧��ݒ�         * //
    // ******************************* //
    readOnlyChanged();
  }

// ****************** �o�^��ʗp���\�b�h **************************************

  /***************************************************************************
   * �����ؑ֐�����s�����\�b�h�ł��B(�o�^��ʗp)
   * @param flag - 0:�L��  1:����
   ***************************************************************************
   */
  public void disabledChanged(
    String flag
  )
  {
    // �O���o��������:�o�^PVO�擾
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();    
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)vendorSupplyMakePvo.first();

    // �t���O��0:�L���̏ꍇ
    if ("0".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled",  Boolean.FALSE); // �K�p�{�^��������
    
    // �t���O��1:�����̏ꍇ
    } else if ("1".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled",  Boolean.TRUE); // �K�p�{�^�������s��

    }
  }
  
  /***************************************************************************
   * ���͐�����s�����\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void readOnlyChangedMake()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    String peopleCode         = (String)params.get("PeopleCode");        // �]�ƈ��敪
    String processFlag        = (String)params.get("ProcessFlag");       // �����t���O
    String productResultType  = (String)params.get("ProductResultType"); // �����^�C�v
    
    // �O���o��������:�o�^PVO�擾
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();    
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)vendorSupplyMakePvo.first();

    // �����t���O��1:�o�^�̏ꍇ
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag))
    {
      readOnlyRow.setAttribute("ManufacturedDateReadOnly",  Boolean.FALSE); // ���Y�����͉�
      readOnlyRow.setAttribute("FactoryCodeReadOnly",       Boolean.FALSE); // �H����͉�
      readOnlyRow.setAttribute("ItemCodeReadOnly",          Boolean.FALSE); // �i�ړ��͉�
      readOnlyRow.setAttribute("ProductedDateReadOnly",     Boolean.FALSE); // ���������͉�
      readOnlyRow.setAttribute("ProductedQuantityReadOnly", Boolean.FALSE); // �o�������ʓ��͉�
      readOnlyRow.setAttribute("CorrectedQuantityReadOnly", Boolean.TRUE);  // �������ʓ��͕s��
      
      // �]�ƈ��敪��1:�������[�U�[�̏ꍇ
      if (XxpoConstants.PEOPLE_CODE_I.equals(peopleCode)) 
      {
        readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.FALSE); // �������͉�
    
      // �]�ƈ��敪��2:�O�����[�U�[�̏ꍇ
      } else if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode)) 
      {
        readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.TRUE);  // �������͕s��
      }
    
    // �����t���O��2:�X�V�̏ꍇ
    } else if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      readOnlyRow.setAttribute("ManufacturedDateReadOnly", Boolean.TRUE); // ���Y�����͕s��
      readOnlyRow.setAttribute("VendorCodeReadOnly",       Boolean.TRUE); // �������͕s��
      readOnlyRow.setAttribute("FactoryCodeReadOnly",      Boolean.TRUE); // �H����͕s��
      readOnlyRow.setAttribute("ItemCodeReadOnly",         Boolean.TRUE); // �i�ړ��͕s��
      readOnlyRow.setAttribute("ProductedDateReadOnly",    Boolean.TRUE); // ���������͕s��

      // �����^�C�v��1:�����݌ɂ̏ꍇ
      if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
      {
        readOnlyRow.setAttribute("ProductedQuantityReadOnly", Boolean.FALSE); // �o�������ʓ��͉�
        readOnlyRow.setAttribute("CorrectedQuantityReadOnly", Boolean.TRUE);  // �������ʓ��͕s��
      // �����^�C�v��2:�����d���̏ꍇ        
      } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
      {
        readOnlyRow.setAttribute("ProductedQuantityReadOnly", Boolean.TRUE);  // �o�������ʓ��͕s��
        readOnlyRow.setAttribute("CorrectedQuantityReadOnly", Boolean.FALSE); // �������ʓ��͉�        
      }
    }
  }

  /***************************************************************************
   * �K�{������s�����\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void requiredChanged()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    String itemClassCode   = (String)params.get("ItemClassCode");  // �i�ڋ敪
    
    // �O���o��������:�o�^PVO�擾
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();    
    // 1�s�ڂ��擾
    OARow requiredRow = (OARow)vendorSupplyMakePvo.first();

    // �i�ڋ敪��5�F���i�̏ꍇ
    if (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode)) 
    {
      requiredRow.setAttribute("ProductedDateRequired", "uiOnly"); // �������K�{
      
    // ���̑��̏ꍇ
    } else
    {
      requiredRow.setAttribute("ProductedDateRequired", "no"); // �������K�{����
    }
  }

  /***************************************************************************
   * ���[�U�[�����擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getUserDataMake()
  {
    // ���[�U�[���擾  
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // �g�����U�N�V����
                          );

    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();   
    // �]�ƈ��敪���Z�b�g
    vendorSupplyMakeRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // �]�ƈ��敪
    // �]�ƈ��敪��2:�O���̏ꍇ�A�d��������Z�b�g
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      vendorSupplyMakeRow.setAttribute("VendorCode",        retHashMap.get("VendorCode"));        // �����R�[�h
      vendorSupplyMakeRow.setAttribute("VendorName",        retHashMap.get("VendorName"));        // ����於
      vendorSupplyMakeRow.setAttribute("VendorId",          retHashMap.get("VendorId"));          // �����ID
      vendorSupplyMakeRow.setAttribute("ProductResultType", retHashMap.get("ProductResultType")); // �����^�C�v
      vendorSupplyMakeRow.setAttribute("Department",        retHashMap.get("Department"));        // ����      
    }
  }
  
  /***************************************************************************
   * �ܖ��������擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getUseByDate()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    Date productedDate   = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");   // ������
    Number itemId        = (Number)vendorSupplyMakeRow.getAttribute("ItemId");        // �i��ID
// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147�Ή�
    String itemCode      = (String)vendorSupplyMakeRow.getAttribute("ItemCode");  // �i�ڃR�[�h
// 2009-02-06 H.Itou Add End
    String expirationDay = (String)vendorSupplyMakeRow.getAttribute("ExpirationDay"); // �ܖ�����

// 2009-02-06 H.Itou Del Start �{�ԏ�Q#1147�Ή�
//    // �ܖ����Ԃɒl������ꍇ�A�ܖ������擾
//    if (XxcmnUtility.isBlankOrNull(expirationDay) == false)
//    {
// 2009-02-06 H.Itou Del End
      Date useByDate = XxpoUtility.getUseByDate(
                         getOADBTransaction(), // �g�����U�N�V����
                         itemId,               // �i��ID
                         productedDate,        // ������
// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147�Ή�
//                         expirationDay         // �ܖ�����
                         itemCode              // �i�ڃR�[�h
// 2009-02-06 H.Itou Add End
                       );
      // �ܖ��������O���o�������:�o�^VO�ɃZ�b�g
      vendorSupplyMakeRow.setAttribute("UseByDate", useByDate);
// 2009-02-06 H.Itou Del Start �{�ԏ�Q#1147�Ή�    
//    // �ܖ����Ԃɒl���Ȃ��ꍇ�ANULL
//    } else
//    {
//      // �ܖ��������O���o�������:�o�^VO�ɃZ�b�g
//      vendorSupplyMakeRow.setAttribute("UseByDate", "");      
//    }
// 2009-02-06 H.Itou Del End
  }

  /***************************************************************************
   * �ŗL�L�����擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getKoyuCode()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾        
    Number itemId         = (Number)vendorSupplyMakeRow.getAttribute("ItemId");         // �i��ID
    Number factoryId      = (Number)vendorSupplyMakeRow.getAttribute("FactoryId");      // �H��ID
    Date manufacturedDate = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate"); // ���Y��
// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1178
    Date productedDate    = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");    // ������
    String unitPriceCalcCode = (String)vendorSupplyMakeRow.getAttribute("UnitPriceCalcCode");// �d���P�����o���^�C�v
    Date standardDate; // ���

    // �d���P���������^�C�v��1:�������̏ꍇ
    if ("1".equals(unitPriceCalcCode))
    {
      // ����͐�����
      standardDate = productedDate;

    // �d���P���������^�C�v��2:���Y���̏ꍇ
    } else
    {
      // ����͐��Y��
      standardDate = manufacturedDate;
    }
// 2009-02-18 H.Itou Add End
        
    // �ŗL�L���擾
    String koyuCode = XxpoUtility.getKoyuCode(
                        getOADBTransaction(), // �g�����U�N�V����
                        itemId,            // �i��ID
                        factoryId,         // �H��ID
// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1178
//                        manufacturedDate   // ���Y��
                        standardDate       // ���
// 2009-02-18 H.Itou Add End
                      );
    
    vendorSupplyMakeRow.setAttribute("KoyuCode", koyuCode);
  }

  /***************************************************************************
   * ���������擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getProductedDate()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾        
    Date manufacturedDate = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate"); // ���Y��
    Date productedDate    = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");    // ������

    // ��������Null�̏ꍇ�A���Y�����Z�b�g
    if (XxcmnUtility.isBlankOrNull(productedDate))
    {
      vendorSupplyMakeRow.setAttribute("ProductedDate", manufacturedDate); // ������
    }
  }

  /***************************************************************************
   * ���̓`�F�b�N���s�����\�b�h�ł��B(�o�^��ʗp)
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void messageTextCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    Object manufacturedDate  = vendorSupplyMakeRow.getAttribute("ManufacturedDate");      // ���Y��
    Object vendorCode        = vendorSupplyMakeRow.getAttribute("VendorCode");            // �����
    Object factoryCode       = vendorSupplyMakeRow.getAttribute("FactoryCode");           // �H��R�[�h
    Object itemCode          = vendorSupplyMakeRow.getAttribute("ItemCode");              // �i�ڃR�[�h
    Object productedDate     = vendorSupplyMakeRow.getAttribute("ProductedDate");         // ������
    Object koyuCode          = vendorSupplyMakeRow.getAttribute("KoyuCode");              // �ŗL�L��
    Object productedQuantity = vendorSupplyMakeRow.getAttribute("ProductedQuantity");     // ����
    Object productedUom      = vendorSupplyMakeRow.getAttribute("ProductedUom");          // ����(�P�ʃR�[�h)
    Object correctedQuantity = vendorSupplyMakeRow.getAttribute("CorrectedQuantity");     // ��������
    Object itemClassCode     = vendorSupplyMakeRow.getAttribute("ItemClassCode");         // �i�ڋ敪
    String costManageCode    = (String)vendorSupplyMakeRow.getAttribute("CostManageCode");// �����Ǘ��敪
// 2008-07-11 D.Nihei ADD START
    String productResultType = (String)vendorSupplyMakeRow.getAttribute("ProductResultType");// �����^�C�v
    String processFlag       = (String)vendorSupplyMakeRow.getAttribute("ProcessFlag");      // �����t���O
    // �V�X�e�����t���擾
    Date currentDate = getOADBTransaction().getCurrentDBDate();
// 2008-07-11 D.Nihei ADD END
// 2008-07-22 H.Itou  ADD START
    Number conversionFactor = (Number)vendorSupplyMakeRow.getAttribute("ConversionFactor"); // ���Z����
// 2008-07-22 H.Itou  ADD END
    
    // ���Y���K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(manufacturedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ManufacturedDate",
                            manufacturedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
// 2008-07-11 D.Nihei ADD START
    // �����^�C�v���u1�F�����݌ɊǗ��v�Ŋ��A���Y�����������̏ꍇ
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)
            && XxcmnUtility.chkCompareDate(1, (Date)manufacturedDate, currentDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ManufacturedDate",
                            manufacturedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
// 2008-07-11 D.Nihei ADD END
    }
    
    // �����K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(vendorCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "VendorCode",
                            vendorCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
    }
    
    // �H��R�[�h�K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(factoryCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "FactoryCode",
                            factoryCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
    }
    
    // �i�ڕK�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(itemCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ItemCode",
                            itemCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
                            
// 2008-07-22 H.Itou  ADD START
    // �i�ڂ̃P�[�X�����`�F�b�N NULL��0�ȉ��̓G���[
    } else if (XxcmnUtility.isBlankOrNull(conversionFactor)
      || (XxcmnUtility.intValue(conversionFactor) <= 0))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ItemCode",
                            itemCode,
                            XxcmnConstants.APPL_XXCMN,         
                            XxcmnConstants.XXCMN10603));
    }
// 2008-07-22 H.Itou  ADD END

    // �i�ڋ敪��5�F���i�̏ꍇ�A�������A�ŗL�L���K�{
    if (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode)) 
    {
      // �������K�{�`�F�b�N
      if (XxcmnUtility.isBlankOrNull(productedDate)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedDate",
                              productedDate,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10002));
      }
      
      // �ŗL�L���K�{�`�F�b�N
      if (XxcmnUtility.isBlankOrNull(koyuCode)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "KoyuCode",
                              koyuCode,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10002));
      }
    }

    // ���ʕK�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(productedQuantity)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ProductedQuantity",
                            productedQuantity,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
                            
    // ���͂�����ꍇ�͐��l�`�F�b�N
    } else
    {
      // ���l�łȂ��ꍇ�̓G���[
      if (!XxcmnUtility.chkNumeric(productedQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedQuantity",
                              productedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

// 2008-07-11 D.Nihei ADD START
      // �V�K�̏ꍇ�́A����0���G���[�Ƃ���
      } else if(XxpoConstants.PROCESS_FLAG_I.equals(processFlag) 
            &&  XxcmnUtility.chkCompareNumeric(2, XxcmnConstants.STRING_ZERO, productedQuantity))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedQuantity",
                              productedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10227));
// 2008-07-11 D.Nihei ADD END
// 2008-07-11 D.Nihei MOD START
//      // �}�C�i�X�l�̓G���[
//      } else if(!XxcmnUtility.chkCompareNumeric(2, productedQuantity, "0"))
      // �X�V�̏ꍇ�́A�}�C�i�X�l���G���[�Ƃ���
      } else if(XxpoConstants.PROCESS_FLAG_U.equals(processFlag) 
            &&  XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, productedQuantity))
// 2008-07-11 D.Nihei MOD END
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedQuantity",
                              productedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
      }
    }
    
    // ����(�P�ʃR�[�h)�K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(productedUom)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ProductedUom",
                            productedUom,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
    }

    // �������l�`�F�b�N
    // ���͂���̏ꍇ�̂�
    if (XxcmnUtility.isBlankOrNull(correctedQuantity) == false)
    {
      // ���l�łȂ��ꍇ�̓G���[
      if (!XxcmnUtility.chkNumeric(correctedQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "CorrectedQuantity",
                              correctedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

      // �}�C�i�X�l�̓G���[
      } else if(!XxcmnUtility.chkCompareNumeric(2, correctedQuantity, "0"))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "CorrectedQuantity",
                              correctedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
      }
    }
  }

  /***************************************************************************
   * �����^�C�v�`�F�b�N���s�����\�b�h�ł��B(�o�^��ʗp)
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void productResultTypeCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    Object productResultType  = vendorSupplyMakeRow.getAttribute("ProductResultType"); // �����^�C�v
    Object vendorCode         = vendorSupplyMakeRow.getAttribute("VendorCode");        // �����

    // �����^�C�v0:���Y���тȂ� �̏ꍇ�A�G���[
    if (XxpoConstants.PRODUCT_RESULT_TYPE_M.equals(productResultType))
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_ENTRY);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_DATA,  XxpoConstants.TOKEN_NAME_DATA);
      
      // �G���[���b�Z�[�W�擾
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "VendorCode",
                            vendorCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10003,
                            tokens));
    }
  }

// 2008-10-23 H.Itou Add Start
  /***************************************************************************
   * �q�ɊǗ����`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void customerStockWhseCheck() throws OAException 
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    Object productResultType  = vendorSupplyMakeRow.getAttribute("ProductResultType"); // �����^�C�v
    Object customerStockWhse  = vendorSupplyMakeRow.getAttribute("CustomerStockWhse"); // �����݌ɊǗ��Ώ�
    Object factoryCode        = vendorSupplyMakeRow.getAttribute("FactoryCode");       // �H��R�[�h

    // �����݌ɊǗ��Ώۃt���O��NULL�̏ꍇ�G���[
    if (XxcmnUtility.isBlankOrNull(customerStockWhse))
    {
      // �G���[���b�Z�[�W�擾
      throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10274);
    
    // �����^�C�v1:�����݌ɂŁA�����݌ɊǗ��Ώۃt���O��1�F�����݌ɊǗ��q�ɂłȂ��ꍇ�A�G���[
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)
             && !XxpoConstants.CUSTOMER_STOCK_WHSE_AITE.equals(customerStockWhse))
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = {new MessageToken(XxpoConstants.TOKEN_VALUE, XxpoConstants.TOKEN_CUSTOMER_STOCK_WHSE_AITE)};
        
      // �G���[���b�Z�[�W�擾
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10275,
                             tokens);

    // �����^�C�v2:�����d���ŁA�����݌ɊǗ��Ώۃt���O��0�F�ɓ����݌ɊǗ��q�ɂłȂ��ꍇ�A�G���[
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType)
             && !XxpoConstants.CUSTOMER_STOCK_WHSE_ITOEN.equals(customerStockWhse))
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = {new MessageToken(XxpoConstants.TOKEN_VALUE, XxpoConstants.TOKEN_CUSTOMER_STOCK_WHSE_ITOEN)};
      
      // �G���[���b�Z�[�W�擾
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10275,
                              tokens);
    }
  }
// 2008-10-23 H.Itou Add End
  /***************************************************************************
   * �݌ɃN���[�Y�`�F�b�N���s�����\�b�h�ł��B(�o�^��ʗp)
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void stockCloseCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    Date manufacturedDate  = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate"); // ���Y��
    
    // �݌ɃN���[�Y�`�F�b�N
    if (XxpoUtility.chkStockClose(
          getOADBTransaction(), // �g�����U�N�V����
          manufacturedDate)     // ���Y��
        ) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ManufacturedDate",
                            manufacturedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10004));
    }    
  }
  /***************************************************************************
   * ���b�g���݊m�F�`�F�b�N���s�����\�b�h�ł��B(�o�^��ʗp)
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void lotCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    Number itemId        = (Number)vendorSupplyMakeRow.getAttribute("ItemId");      // �i��ID
    Date   productedDate = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate"); // ������
    String koyuCode      = (String)vendorSupplyMakeRow.getAttribute("KoyuCode");    // �ŗL�L��

    // ���b�g���݊m�F�`�F�b�N
    if (XxpoUtility.chkLotMst(
          getOADBTransaction(), // �g�����U�N�V����
          itemId,               // �i��ID
          productedDate,        // ������ 
          koyuCode              // �ŗL�L��
          )
        ) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            null,
                            null,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10005));
    }    
  }

  /***************************************************************************
   * �����\���ʃ`�F�b�N���s�����\�b�h�ł��B(�o�^��ʗp)
   * @param exceptions - �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap reservedQuantityCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    String productedQuantity = (String)vendorSupplyMakeRow.getAttribute("ProductedQuantity");// ����
    Number txnsId            = (Number)vendorSupplyMakeRow.getAttribute("TxnsId");           // ����ID

    // �����\���`�F�b�N
    HashMap paramsRet = XxpoUtility.chkReservedQuantity(
                          getOADBTransaction(), // �g�����U�N�V����
                          productedQuantity,    // �o��������
                          txnsId                // ����ID
                          );
    return paramsRet;
  }

  /***************************************************************************
   * �݌ɒP�����擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getStockValue()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^���擾
    String costManageCode    = (String)vendorSupplyMakeRow.getAttribute("CostManageCode");   // �����Ǘ��敪
    String productResultType = (String)vendorSupplyMakeRow.getAttribute("ProductResultType");// �����^�C�v
    String unitPriceCalcCode = (String)vendorSupplyMakeRow.getAttribute("UnitPriceCalcCode");// �d���P�����o���^�C�v
    Number itemId            = (Number)vendorSupplyMakeRow.getAttribute("ItemId");           // �i��ID
    Number vendorId          = (Number)vendorSupplyMakeRow.getAttribute("VendorId");         // �����ID
    Number factoryId         = (Number)vendorSupplyMakeRow.getAttribute("FactoryId");        // �H��ID
    Date manufacturedDate    = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate");   // ���Y��
    Date productedDate       = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");      // ������

    // �p�����[�^�쐬
    HashMap params = new HashMap();
    params.put("CostManageCode",    costManageCode);   // �����Ǘ��敪
    params.put("ProductResultType", productResultType);// �����^�C�v
    params.put("UnitPriceCalcCode", unitPriceCalcCode);// �d���P�����o���^�C�v
    params.put("ItemId",            itemId);           // �i��ID
    params.put("VendorId",          vendorId);         // �����ID
    params.put("FactoryId",         factoryId);        // �H��ID
    params.put("ManufacturedDate",  manufacturedDate); // ���Y��
    params.put("ProductedDate",     productedDate);    // ������
    // �݌ɒP���擾���s
    String stockValue = XxpoUtility.getStockValue(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );

    vendorSupplyMakeRow.setAttribute("StockValue", stockValue);
  }

  /***************************************************************************
   * �����ԍ����擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getPoNumber()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();

    // �����ԍ��擾���s
    String poNumber = XxpoUtility.getPoNumber(
                          getOADBTransaction() // �g�����U�N�V����
                          );

    vendorSupplyMakeRow.setAttribute("PoNumber", poNumber);
  }

  /***************************************************************************
   * �[��������擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getLocationData()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �f�[�^�擾
    String productResultType = (String)vendorSupplyMakeRow.getAttribute("ProductResultType");// �����^�C�v
    String vendorStockWhse   = (String)vendorSupplyMakeRow.getAttribute("VendorStockWhse");  // �����݌ɓ��ɐ�
    String deliveryWhse      = (String)vendorSupplyMakeRow.getAttribute("DeliveryWhse");     // �����[����
    String locationCode      = null;

    // �����^�C�v1:�����݌ɂ̏ꍇ�A
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
    {
      // �����݌ɓ��ɐ悩��[��������擾
      locationCode = vendorStockWhse;

    // �����^�C�v2:�����d���̏ꍇ�A
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      // �����[���悩��[��������擾
      locationCode = deliveryWhse;
      
    }
      // �����݌ɓ��ɐ悩��[��������擾
      HashMap retHashMap = XxpoUtility.getLocationData(
                            getOADBTransaction(),  // �g�����U�N�V����
                            locationCode           // �[����
                            );

      vendorSupplyMakeRow.setAttribute("LocationId",       retHashMap.get("LocationId"));       // �[����ID
      vendorSupplyMakeRow.setAttribute("WhseCode",         retHashMap.get("WhseCode"));         // �q�ɃR�[�h
      vendorSupplyMakeRow.setAttribute("LocationCode",     locationCode);                       // �[����R�[�h
      vendorSupplyMakeRow.setAttribute("CoCode",           retHashMap.get("CoCode"));           // ��ЃR�[�h
      vendorSupplyMakeRow.setAttribute("OrgnCode",         retHashMap.get("OrgnCode"));         // �g�D�R�[�h
      vendorSupplyMakeRow.setAttribute("ShipToLocationId", retHashMap.get("ShipToLocationId")); // �[���掖�Ə�ID
      vendorSupplyMakeRow.setAttribute("OrganizationId",   retHashMap.get("OrganizationId"));   // �݌ɑg�DID
// 2008-10-23 H.Itou Add Start �����݌ɊǗ��Ώۂ�ǉ�
      vendorSupplyMakeRow.setAttribute("CustomerStockWhse", retHashMap.get("CustomerStockWhse"));   // �����݌ɊǗ��Ώ�
// 2008-10-23 H.Itou Add End
  }

  /***************************************************************************
   * �����˗�No���擾���郁�\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void getQtInspectReqNo()
  {   
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();

    // �����ԍ��擾���s
    Object qtInspectReqNo = XxpoUtility.getQtInspectReqNo(
                          getOADBTransaction(), // �g�����U�N�V����
                          params
                          );
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first(); 

    vendorSupplyMakeRow.setAttribute("QtInspectReqNo", qtInspectReqNo);
  }
  
  /***************************************************************************
   * �O���o����VO��HashMap�Ɋi�[���郁�\�b�h�ł��B(�o�^��ʗp)
   * @return HashMap - �O���o����VO HashMap
   ***************************************************************************
   */
  public HashMap getAllDataHashMap()
  {
    HashMap params = new HashMap();

    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();        
        
    // �d����֘A�f�[�^
    params.put("VendorId",          vendorSupplyMakeRow.getAttribute("VendorId"));          // �����ID
    params.put("VendorCode",        vendorSupplyMakeRow.getAttribute("VendorCode"));        // �����
    params.put("VendorName",        vendorSupplyMakeRow.getAttribute("VendorName"));        // ����於
    params.put("ProductResultType", vendorSupplyMakeRow.getAttribute("ProductResultType")); // �����^�C�v
    params.put("Department",        vendorSupplyMakeRow.getAttribute("Department"));        // ����
    // �d����T�C�g�֘A�f�[�^
    params.put("FactoryId",         vendorSupplyMakeRow.getAttribute("FactoryId"));         // �H��ID
    params.put("FactoryCode",       vendorSupplyMakeRow.getAttribute("FactoryCode"));       // �H��R�[�h
    params.put("FactoryName",       vendorSupplyMakeRow.getAttribute("FactoryName"));       // �H�ꖼ
    params.put("VendorStockWhse",   vendorSupplyMakeRow.getAttribute("VendorStockWhse"));   // �����݌ɓ��ɐ�
    params.put("DeliveryWhse",      vendorSupplyMakeRow.getAttribute("DeliveryWhse"));      // �����[����
    // �i�ڊ֘A�f�[�^
    params.put("ItemId",            vendorSupplyMakeRow.getAttribute("ItemId"));            // �i��ID
    params.put("ItemCode",          vendorSupplyMakeRow.getAttribute("ItemCode"));          // �i�ڃR�[�h
    params.put("ItemName",          vendorSupplyMakeRow.getAttribute("ItemName"));          // �i�ږ�
    params.put("CostManageCode",    vendorSupplyMakeRow.getAttribute("CostManageCode"));    // �����Ǘ��敪
    params.put("TestCode",          vendorSupplyMakeRow.getAttribute("TestCode"));          // �����L���敪
    params.put("LotStatus",         vendorSupplyMakeRow.getAttribute("LotStatus"));         // ���b�g�X�e�[�^�X
    if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(params.get("ProductResultType")))    // �����^�C�v��2:�����d���̏ꍇ
    {
      params.put("StockQty",        vendorSupplyMakeRow.getAttribute("StockQty"));          // �݌ɓ���     
    } 
    params.put("Uom",               vendorSupplyMakeRow.getAttribute("Uom"));               // ����(�P�ʃR�[�h)
    params.put("ProductedUom",      vendorSupplyMakeRow.getAttribute("ProductedUom"));      // �o��������(�P�ʃR�[�h)
    params.put("ConversionFactor",  vendorSupplyMakeRow.getAttribute("ConversionFactor"));  // ���Z����
    params.put("ExpirationDay",     vendorSupplyMakeRow.getAttribute("ExpirationDay"));     // �ܖ�����
    params.put("UnitPriceCalcCode", vendorSupplyMakeRow.getAttribute("UnitPriceCalcCode")); // �d���P�����o���^�C�v
    params.put("InventoryItemId",   vendorSupplyMakeRow.getAttribute("InventoryItemId"));   // INV�i��ID
    params.put("ItemClassCode",     vendorSupplyMakeRow.getAttribute("ItemClassCode"));     // �i�ڋ敪
    // ��ʂ���擾�����f�[�^
    params.put("TxnsId",            vendorSupplyMakeRow.getAttribute("TxnsId"));            // ����ID
    params.put("ManufacturedDate",  vendorSupplyMakeRow.getAttribute("ManufacturedDate"));  // ���Y��
    params.put("ProductedDate",     vendorSupplyMakeRow.getAttribute("ProductedDate"));     // ������
    params.put("KoyuCode",          vendorSupplyMakeRow.getAttribute("KoyuCode"));          // �ŗL�L��
    params.put("UseByDate",         vendorSupplyMakeRow.getAttribute("UseByDate"));         // �ܖ�����
    params.put("Quantity",          vendorSupplyMakeRow.getAttribute("Quantity"));          // ����
    params.put("ProductedQuantity", vendorSupplyMakeRow.getAttribute("ProductedQuantity")); // �o��������
    params.put("CorrectedQuantity", vendorSupplyMakeRow.getAttribute("CorrectedQuantity")); // ��������
    params.put("Description",       vendorSupplyMakeRow.getAttribute("Description"));       // ���l
    params.put("LastUpdateDate",    vendorSupplyMakeRow.getAttribute("LastUpdateDate"));    // �ŏI�X�V��
    // �����ԍ��擾(getPoNumber)�Ŏ擾�����f�[�^
    params.put("PoNumber",          vendorSupplyMakeRow.getAttribute("PoNumber"));          // �����ԍ�
    // �݌ɒP���擾(getStockValue)�Ŏ擾�����f�[�^
    params.put("StockValue",        vendorSupplyMakeRow.getAttribute("StockValue"));        // �݌ɒP��
    // ���b�g�}�X�^�o�^����(insertLotMst)�Ŏ擾�����f�[�^
    params.put("LotNumber",         vendorSupplyMakeRow.getAttribute("LotNumber"));         // ���b�g�ԍ�
    params.put("LotId",             vendorSupplyMakeRow.getAttribute("LotId"));             // ���b�gID    
// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
    params.put("CreateLotDiv",      vendorSupplyMakeRow.getAttribute("CreateLotDiv"));      // �쐬�敪
// 2009-02-18 H.Itou Add End
    // �[������擾(getLocationData)�Ŏ擾�����f�[�^
    params.put("LocationId",        vendorSupplyMakeRow.getAttribute("LocationId"));        // �[����ID
    params.put("LocationCode",      vendorSupplyMakeRow.getAttribute("LocationCode"));      // �[����R�[�h
    params.put("WhseCode",          vendorSupplyMakeRow.getAttribute("WhseCode"));          // �q�ɃR�[�h    
    params.put("CoCode",            vendorSupplyMakeRow.getAttribute("CoCode"));            // ��ЃR�[�h
    params.put("OrgnCode",          vendorSupplyMakeRow.getAttribute("OrgnCode"));          // �g�D�R�[�h
    params.put("ShipToLocationId",  vendorSupplyMakeRow.getAttribute("ShipToLocationId"));  // �[���掖�Ə�ID
    params.put("OrganizationId",    vendorSupplyMakeRow.getAttribute("OrganizationId"));    // �݌ɑg�DID
// 2008-10-23 H.Itou Add Start �����݌ɊǗ��Ώۂ�ǉ�
    params.put("CustomerStockWhse", vendorSupplyMakeRow.getAttribute("CustomerStockWhse")); // �����݌ɊǗ��Ώ�
// 2008-10-23 H.Itou Add End
      
    // �����t���O1:�o�^ 2:�X�V
    params.put("ProcessFlag",       vendorSupplyMakeRow.getAttribute("ProcessFlag"));
    // �]�ƈ��敪1:���� 2:�O��
    params.put("PeopleCode",       vendorSupplyMakeRow.getAttribute("PeopleCode"));

    // �i�������˗����쐬�E�X�V�Ɏg�p����f�[�^
    // �����^�C�v��1:�����݌ɂ̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(params.get("ProductResultType")))
    {
      params.put("Division",        "4"); // �敪 4:�O���o����

    // �����^�C�v��2:�����d���̏ꍇ
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(params.get("ProductResultType"))) 
    {
      params.put("Division",        "2"); // �敪 2:����
    }
    params.put("QtInspectReqNo",    vendorSupplyMakeRow.getAttribute("QtInspectReqNo")); // �����˗�No

    return params;
    
  }
 
  /***************************************************************************
   * ���b�g�}�X�^�o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insLotMst()
  {

    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �l���擾
    Number itemId    = (Number)vendorSupplyMakeRow.getAttribute("ItemId");    // �i��ID
    String itemCode  = (String)vendorSupplyMakeRow.getAttribute("ItemCode");  // �i�ڃR�[�h
    String lotStatus = (String)vendorSupplyMakeRow.getAttribute("LotStatus"); // �i��ID
    
    // ���b�g�ԍ��擾
    String lotNumber = XxpoUtility.getLotNumber(
                         getOADBTransaction(), // �g�����U�N�V����
                         itemId,               // �i��ID
                         itemCode              // �i�ڃR�[�h
                         );
                         
    vendorSupplyMakeRow.setAttribute("LotNumber", lotNumber);


    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    // ���b�g�쐬API ���s
    HashMap retHashMap = XxpoUtility.insertLotMst(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
    // ���b�gID�擾                      
    vendorSupplyMakeRow.setAttribute("LotId", retHashMap.get("LotId"));
    
    return (String)retHashMap.get("RetFlag");
  }

  /***************************************************************************
   * �����݌Ƀg�����U�N�V�����o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insInventoryPosting()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertInventoryPosting(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * ���b�g�����o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insLotCost()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertLotCostAdjustment(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * �O���o�������ѓo�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insXxpoVendorSupplyTxns()
  {

    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();

    // �O���o�������ѓo�^ ���s
    HashMap retHashMap = XxpoUtility.insertXxpoVendorSupplyTxns(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // ����ID�Z�b�g
    vendorSupplyMakeRow.setAttribute("TxnsId", retHashMap.get("TxnsId"));
    
    return (String)retHashMap.get("RetFlag");
  }

  /***************************************************************************
   * �����w�b�_(�A�h�I��)�o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insXxpoHeadersAll()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertXxpoHeadersAll(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * �����w�b�_�I�[�v��IF�o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insPoHeadersIf()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertPoHeadersIf(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * �������׃I�[�v��IF�o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insPoLinesIf()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertPoLinesIf(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * �������׃I�[�v��IF�o�^�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insPoDistributionsIf()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertPoDistributionsIf(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * �i�������˗������s�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String doQtInspection()
  {
    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.doQtInspection(
                          getOADBTransaction(), // �g�����U�N�V����
                          params                // �p�����[�^
                          );
  }

  /***************************************************************************
   * �O���o�������эX�V�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String updXxpoVendorSupplyTxns()
  {

    // �O���o����VO�f�[�^�擾
    HashMap params = getAllDataHashMap();

    // �O���o�������ѓo�^ ���s
    return XxpoUtility.updateXxpoVendorSupplyTxns(
              getOADBTransaction(), // �g�����U�N�V����
              params                // �p�����[�^
              );
  }

  /***************************************************************************
   * VO�̏������������s�����\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void initializeMake()
  {
    // ************************************* //
    // * �O���o������:�o�^VO ��s�擾    * //
    // ************************************* //
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!vendorSupplyMakeVo.isPreparedForExecution())
    {
      vendorSupplyMakeVo.setWhereClauseParam(0,null);
      vendorSupplyMakeVo.executeQuery();
      vendorSupplyMakeVo.insertRow(vendorSupplyMakeVo.createRow());
      // 1�s�ڂ��擾
      OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
      // �L�[�ɒl���Z�b�g
      vendorSupplyMakeRow.setNewRowState(Row.STATUS_INITIALIZED);
      vendorSupplyMakeRow.setAttribute("TxnsId", new Number(-1));
    }
    
    // ************************************* //
    // * �O���o������:�o�^PVO ��s�擾   * //
    // ************************************* //
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();   
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!vendorSupplyMakePvo.isPreparedForExecution())
    {    
      // 1�s���Ȃ��ꍇ�A��s�쐬
      vendorSupplyMakePvo.setMaxFetchSize(0);
      vendorSupplyMakePvo.executeQuery();
      vendorSupplyMakePvo.insertRow(vendorSupplyMakePvo.createRow());
      // 1�s�ڂ��擾
      OARow vendorSupplyMakePvoRow = (OARow)vendorSupplyMakePvo.first();
      // �L�[�ɒl���Z�b�g
      vendorSupplyMakePvoRow.setAttribute("RowKey", new Number(1));
    }    
  }

  /***************************************************************************
   * �����������s�����\�b�h�ł��B(�o�^��ʗp)
   * @param searchTxnsId - �����p�����[�^����ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearch(String searchTxnsId) throws OAException
  {
    // �O���o�������:�o�^VO�擾
    XxpoVendorSupplyMakeVOImpl vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // ����
    vendorSupplyMakeVo.initQuery(searchTxnsId);         // �����p�����[�^����ID
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();

    // �f�[�^���擾�ł��Ȃ������ꍇ
    if (vendorSupplyMakeVo.getRowCount() == 0)
    {
      // *********************** //
      // *  VO����������       * //
      // *********************** //
      OAViewObject vo = getXxpoVendorSupplyMakeVO1();
      vo.setWhereClauseParam(0,null);
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      // 1�s�ڂ��擾
      OARow row = (OARow)vo.first();
      // �L�[�ɒl���Z�b�g
      row.setNewRowState(Row.STATUS_INITIALIZED);
      row.setAttribute("TxnsId", new Number(-1));
      
      // *********************** //
      // *  �����ؑ֏���       * //
      // *********************** //
      disabledChanged("1"); // �����ɐݒ�

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
    
    // �f�[�^���擾�ł����ꍇ
    else 
    {
      // �����t���O2:�X�V���Z�b�g
      vendorSupplyMakeRow.setAttribute("ProcessFlag", XxpoConstants.PROCESS_FLAG_U);
      
      // *********************** //
      // *  �����ؑ֏���       * //
      // *********************** //
      disabledChanged("0"); // �L���ɐݒ�
        
      // *********************** //
      // *  ���͐��䏈��       *
      // *********************** //
      readOnlyChangedMake();      

      // *********************** //
      // *  �K�{�ؑ֏���       * //
      // *********************** //
      requiredChanged();
    }
  }

  /***************************************************************************
   * �V�K�s�}���������s�����\�b�h�ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void addRow()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo  = getXxpoVendorSupplyMakeVO1();
    // 1�s�ڂ��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �����t���O1:�o�^���Z�b�g
    vendorSupplyMakeRow.setAttribute("ProcessFlag", XxpoConstants.PROCESS_FLAG_I); // �����t���O 1:�o�^

    // *********************** //
    // * ���[�U�[���擾    * //
    // *********************** //
    getUserDataMake();

    // *********************** //
    // *  �����ؑ֏���       * //
    // *********************** //
    disabledChanged("0"); // �L���ɐݒ�
        
    // *********************** //
    // *  ���͐��䏈��       *
    // *********************** //
    readOnlyChangedMake();      

    // *********************** //
    // *  �K�{�ؑ֏���       * //
    // *********************** //
    requiredChanged();

  }

  /***************************************************************************
   * �����ύX�������ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void vendorCodeChanged()
  {
    // �O���o�������:�o�^VO�擾
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1�s�߂��擾
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // �H��f�[�^�����Z�b�g
    vendorSupplyMakeRow.setAttribute("FactoryCode",     ""); // �H��R�[�h
    vendorSupplyMakeRow.setAttribute("FactoryName",     ""); // �H�ꖼ
    vendorSupplyMakeRow.setAttribute("FactoryId",       ""); // �H��ID
    vendorSupplyMakeRow.setAttribute("DeliveryWhse",    ""); // �����[����
    vendorSupplyMakeRow.setAttribute("VendorStockWhse", ""); // �����݌ɓ��ɐ�
    // �H��f�[�^����擾���鍀�ڂ����Z�b�g
    vendorSupplyMakeRow.setAttribute("KoyuCode",        ""); // �ŗL�L��

    // ���͐���
    readOnlyChangedMake();
  }

  /***************************************************************************
   * �H��ύX�������ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void factoryCodeChanged()
  {
    // �ŗL�L���擾
    getKoyuCode(); 
  }

  /***************************************************************************
   * �i�ڕύX�������ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void itemCodeChanged()
  {
    // �K�{���͐ؑ�
    requiredChanged();
        
    // �ŗL�L���擾
    getKoyuCode(); 
        
    // �ܖ������擾
    getUseByDate(); 
  }

  /***************************************************************************
   * ���Y���ύX�������ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void manufacturedDateChanged()
  {        
    // �ŗL�L���擾
    getKoyuCode();

    // �������擾
    getProductedDate();
    
    // �ܖ������擾
    getUseByDate();
  }

  /***************************************************************************
   * �������ύX�������ł��B(�o�^��ʗp)
   ***************************************************************************
   */
  public void productedDateChanged()
  {
// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1178
    // �ŗL�L���擾
    getKoyuCode(); 
// 2009-02-18 H.Itou Add End

    // �ܖ������擾
    getUseByDate();
  }

  /***************************************************************************
   * �o�^�E�X�V���̃`�F�b�N���s���܂��B(�o�^��ʗp)
   * @return HashMap - ���^�[���R�[�h�A�x�����b�Z�[�W
   ***************************************************************************
   */
  public HashMap allCheck()
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);
    HashMap paramsRet = new HashMap();
    
    // �O���o�������擾
    HashMap params = getAllDataHashMap();
    String costManageCode = (String)params.get("CostManageCode"); // �����Ǘ��敪
    Object processFlag    = (Object)params.get("ProcessFlag");    // �����t���O
    Object itemClassCode  = (Object)params.get("ItemClassCode");  // �i�ڋ敪

// 2009-02-06 H.Itou Add Start �{�ԏ�Q#1147�Ή� �J�[�\���ړ����Ȃ��œK�p�{�^�����������ꍇ��z��B
    // �ŗL�L���ɒl���Ȃ��ꍇ�A�����Z�o
    if (XxcmnUtility.isBlankOrNull(params.get("koyuCode")))
    {
      // ************************** //
      // *   �ŗL�L���Z�o         * //
      // ************************** //
      getKoyuCode();
    }
    // �ܖ������ɒl���Ȃ��ꍇ�A�����Z�o
    if (XxcmnUtility.isBlankOrNull(params.get("useByDate")))
    {
      // ************************** //
      // *   �ܖ������Z�o         * //
      // ************************** //
      getUseByDate();
    }
// 2009-02-06 H.Itou Add End

    // ******************************* //
    // *   �K�{�`�F�b�N              * //
    // ******************************* //
    messageTextCheck(exceptions);
    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // ******************************* //
    // *   �����^�C�v�`�F�b�N        * //
    // ******************************* //
    productResultTypeCheck(exceptions);
    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
// 2008-10-23 H.Itou Add Start �q�ɂ������݌ɊǗ����ɓ����݌ɊǗ����`�F�b�N����B
    // ************************ //
    // *    �[������擾    * //
    // ************************ //
    getLocationData();

    // ************************** //
    // *   �q�ɊǗ����`�F�b�N   * //
    // ************************** //
    customerStockWhseCheck();
// 2008-10-23 H.Itou Add End

    // ******************************* //
    // *   �݌ɃN���[�Y�`�F�b�N      * //
    // ******************************* //
    stockCloseCheck(exceptions);
    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // ******************************* //
    // *   ���b�g���݊m�F�`�F�b�N    * //
    // ******************************* //
    // �V�K�o�^���� �i�ڋ敪��5�F���i�̏ꍇ�A���s
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag) && XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
    {
      lotCheck(exceptions);
      // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }      
    }
    
    // ******************************* //
    // *   �����\���ʃ`�F�b�N      * //
    // ******************************* //
    // �X�V�̏ꍇ�A���s
    if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      paramsRet = reservedQuantityCheck(exceptions);
    // �V�K�̏ꍇ�A�߂�l�Ƀf�t�H���g�l��ݒ�
    } else
    {
      paramsRet.put("PlSqlRet", XxcmnConstants.RETURN_SUCCESS); 
    }
    return paramsRet; 
  }

  /***************************************************************************
   * �o�^�������s���܂��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String insProcess()
  {
    // �O���o�������擾
    HashMap params = getAllDataHashMap();
    String productResultType = (String)params.get("ProductResultType"); // �����^�C�v
    String testCode          = (String)params.get("TestCode");          // �����L���敪
    
    // ************************ //
    // *     �݌ɒP���擾     * //
    // ************************ //
    getStockValue();

    // ************************ //
    // *    �����ԍ��擾      * //
    // ************************ //
    // �����^�C�v2:�����d���̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      getPoNumber();
    }

// 2008-10-23 H.Itou Del Start �`�F�b�N�������Ɏ擾���邽�߁A�폜
//    // ************************ //
//    // *    �[������擾    * //
//    // ************************ //
//    getLocationData();
// 2008-10-23 H.Itou Del End
    // ************************ //
    // * ���b�g�}�X�^�o�^     * //
    // ************************ //
    // ���b�g�o�^����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(insLotMst()))
    {
      return XxcmnConstants.RETURN_NOT_EXE;
    }
    
    // ********************************** //
    // * �O���o��������(�A�h�I��)�o�^   * //
    // ********************************** //
    // �O���o�������ѓo�^������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(insXxpoVendorSupplyTxns()))
    {
      return XxcmnConstants.RETURN_NOT_EXE;
    }

    // �����^�C�v1:�����݌ɊǗ��̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
    {
      // ************************ //
      // * ���b�g�����o�^       * //
      // ************************ //
      // ���b�g�����o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insLotCost()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
    
      // ******************************** //
      // * �����݌Ƀg�����U�N�V�����o�^ * //
      // ******************************** //
      // �����݌Ƀg�����U�N�V�����o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insInventoryPosting()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }

    // �����^�C�v2:�����d���̏ꍇ
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      // **************************** //
      // * �����w�b�_(�A�h�I��)�o�^ * //
      // **************************** //
      // �����w�b�_(�A�h�I��)�o�^������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insXxpoHeadersAll()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
      
      // **************************** //
      // * �����w�b�_�I�[�v��IF�o�^ * //
      // **************************** //
      // �����w�b�_�I�[�v��IF�o�^������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insPoHeadersIf()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
      
      // **************************** //
      // * �������דo�^             * //
      // **************************** //
      // �������׃I�[�v��IF�o�^������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insPoLinesIf()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }

      // **************************** //
      // * �������דo�^             * //
      // **************************** //
      // �������׃I�[�v��IF�o�^������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insPoDistributionsIf()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
    }
    
    // **************************** //
    // * �i�������˗����쐬     * //
    // **************************** //
    // �����L���敪 1:�L�̏ꍇ
    if (XxpoConstants.QT_TYPE_ON.equals(testCode))
    {
      // �i�������˗����o�^������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(doQtInspection()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
    }
    return XxcmnConstants.RETURN_SUCCESS;
  }

  /***************************************************************************
   * �X�V�������s���܂��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String updProcess()
  {
    // �O���o�������擾
    HashMap params = getAllDataHashMap();
    String testCode          = (String)params.get("TestCode");          // �����L���敪
    String productedQuantity = (String)params.get("ProductedQuantity"); // �O���o��������
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // ���Z����
    Number quantity          = (Number)params.get("Quantity");          // ����
    String productResultType = (String)params.get("ProductResultType"); // �����^�C�v
// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
    String createLotDiv      = (String)params.get("CreateLotDiv");      // �쐬�敪
// 2009-02-18 H.Itou Add End
    
    // ********************************** //
    // * �O���o��������(�A�h�I��)�X�V   * //
    // ********************************** //
    // �O���o�������ѓo�^������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(updXxpoVendorSupplyTxns()))
    {
      return XxcmnConstants.RETURN_NOT_EXE;
    }
    
    // ���ʂ���ʂ̊O���o�������ʁ~���Z�����ƈقȂ�ꍇ�݈̂ȉ��̏������s���B
    if (Double.parseDouble(quantity.toString()) != Double.parseDouble(productedQuantity) * Double.parseDouble(conversionFactor.toString()))
    {
        // �����^�C�v1:�����݌ɊǗ��̏ꍇ�̂݊����݌Ƀg�����U�N�V�����쐬
      if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
      {
// 2008-10-23 H.Itou Del Start �`�F�b�N�������Ɏ擾���邽�߁A�폜
//        // ************************ //
//        // *    �[������擾    * //
//        // ************************ //
//        getLocationData();
// 2008-10-23 H.Itou Del End
    
        // ******************************** //
        // * �����݌Ƀg�����U�N�V�����o�^ * //
        // ******************************** //
        // �����݌Ƀg�����U�N�V�����o�^����������I���łȂ��ꍇ
        if (XxcmnConstants.RETURN_NOT_EXE.equals(insInventoryPosting()))
        {
          return XxcmnConstants.RETURN_NOT_EXE;
        }              
      }
// 2009-02-18 H.Itou Del Start �{�ԏ�Q#1096 �X�V�ł��i��������V�K�ō쐬����ꍇ������̂ŁA�ړ��B      
//      // **************************** //
//      // * �i�������˗����쐬     * //
//      // **************************** //
//      // �����L���敪 1:�L�̏ꍇ�̂ݎ��s
//      if (XxpoConstants.QT_TYPE_ON.equals(testCode))
//      {
//        // �����˗�No�擾
//        getQtInspectReqNo();
//      
//        // �i�������˗����o�^������I���łȂ��ꍇ
//        if (XxcmnConstants.RETURN_NOT_EXE.equals(doQtInspection()))
//        {
//          return XxcmnConstants.RETURN_NOT_EXE;
//        }
//      }
// 2009-02-18 H.Itou Del End
    }
// 2009-02-18 H.Itou Add Start �{�ԏ�Q#1096
    // **************************** //
    // * �i�������˗����쐬     * //
    // **************************** //
    // �E�����L���敪 1:�L
    // �E�����^�C�v1:�����݌ɊǗ����A�쐬�敪2:�����݌Ɍv��
    //   �܂��́A
    //   �����^�C�v2:�����d�����A�쐬�敪3:�o�����񍐑����d��
    if (XxpoConstants.QT_TYPE_ON.equals(testCode)
      && (((XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
        && "2".equals(createLotDiv))
      || ((XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
        && "3".equals(createLotDiv))))
    {
      // �i�������˗����o�^������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(doQtInspection()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
    }
// 2009-02-18 H.Itou Add End
    return XxcmnConstants.RETURN_SUCCESS;
  }
  
 /***************************************************************************
   * �o�^�E�X�V�������s���܂��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String mainProcess()
  {
    // �O���o�������擾
    HashMap params = getAllDataHashMap();
    Object processFlag    = (Object)params.get("ProcessFlag"); // �����t���O

    // �����t���O��1:�o�^�̏ꍇ
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag))
    {
      // �o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insProcess()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }      

    // �����t���O��2:�X�V�̏ꍇ
    } else if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      // �X�V����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(updProcess()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }      
    }
    return XxcmnConstants.RETURN_SUCCESS;
  }

  /***************************************************************************
   * �R���J�����g�F�W�������C���|�[�g���s�����ł��B(�o�^��ʗp)
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String doImportPo()
  {
    // �O���o�������擾
    HashMap params = getAllDataHashMap();
    String productResultType = (String)params.get("ProductResultType"); // �����^�C�v
    Object processFlag       = (Object)params.get("ProcessFlag");       // �����t���O
    
    // �����t���O1:�o�^���A�����^�C�v2:�����d���̏ꍇ�̂ݎ��s
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag) && XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
    
      return XxpoUtility.doImportStandardPurchaseOrders(
                            getOADBTransaction(), // �g�����U�N�V����
                            params                // �p�����[�^
                            );      
    }
    return XxcmnConstants.RETURN_SUCCESS;
  }
   
  /***************************************************************************
   * �I���������s�����\�b�h�ł��B(�o�^��ʗp)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doEndOfProcess() throws OAException
  {
    // �O���o�������擾
    HashMap params = getAllDataHashMap();
    Number txnsId      = (Number)params.get("TxnsId");      //����ID
    Object processFlag = (Object)params.get("ProcessFlag"); // �����t���O
      
    // VO����������(�X�V��ʂƂ��čĕ\�����܂��B)
    initializeMake();

    // ����
    doSearch(txnsId.toString());
    
    // �����t���O��1:�o�^�̏ꍇ
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag))
    {
      // �o�^�������b�Z�[�W
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30041, 
        null, 
        OAException.INFORMATION, 
        null);

    // �����t���O��2:�X�V�̏ꍇ
    } else if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      // �X�V�������b�Z�[�W
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30042, 
        null, 
        OAException.INFORMATION, 
        null);
    }
  } // doEndOfProcess
  
  /***************************************************************************
   * �R�~�b�g�������s�����\�b�h�ł��B(�o�^��ʗp)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doCommit(
  ) throws OAException
  {
    // �R�~�b�g
    XxpoUtility.commit(getOADBTransaction());
  } // doCommit
  
  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B(�o�^��ʗp)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doRollBack()
  {
    // ���[���o�b�N
    XxpoUtility.rollBack(getOADBTransaction());
  } // doRollBack

  /**
   * 
   * Container's getter for XxpoVendorSupplyVO1
   */
  public XxpoVendorSupplyVOImpl getXxpoVendorSupplyVO1()
  {
    return (XxpoVendorSupplyVOImpl)findViewObject("XxpoVendorSupplyVO1");
  }


  /**
   * 
   * Container's getter for XxpoVendorSupplySearchVO1
   */
  public XxpoVendorSupplySearchVOImpl getXxpoVendorSupplySearchVO1()
  {
    return (XxpoVendorSupplySearchVOImpl)findViewObject("XxpoVendorSupplySearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoVendorSupplyPVO1
   */
  public XxpoVendorSupplyPVOImpl getXxpoVendorSupplyPVO1()
  {
    return (XxpoVendorSupplyPVOImpl)findViewObject("XxpoVendorSupplyPVO1");
  }

  /**
   * 
   * Container's getter for XxpoVendorSupplyMakeVO1
   */
  public XxpoVendorSupplyMakeVOImpl getXxpoVendorSupplyMakeVO1()
  {
    return (XxpoVendorSupplyMakeVOImpl)findViewObject("XxpoVendorSupplyMakeVO1");
  }

  /**
   * 
   * Container's getter for XxpoVendorSupplyMakePVO1
   */
  public XxpoVendorSupplyMakePVOImpl getXxpoVendorSupplyMakePVO1()
  {
    return (XxpoVendorSupplyMakePVOImpl)findViewObject("XxpoVendorSupplyMakePVO1");
  }
}
