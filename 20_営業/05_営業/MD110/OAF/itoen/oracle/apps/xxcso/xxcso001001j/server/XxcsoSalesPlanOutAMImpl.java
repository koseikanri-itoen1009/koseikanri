/*============================================================================
* �t�@�C���� : XxcsoSalesPlanOutAMImp1
* �T�v����   : ����v��o�́^�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS�ێR�����@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.xxcso001001j.util.XxcsoSalesPlanConstants;

import java.io.UnsupportedEncodingException;

import java.sql.SQLException;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.BlobDomain;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;

/*******************************************************************************
 * ����v��o�́@�A�v���P�[�V�������W���[���N���X
 * @author  SCS�ێR����
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanOutAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanOutAMImpl()
  {
  }
  
  /*****************************************************************************
   * �J�X�^�}�C�Y�u���b�N
   *****************************************************************************
   */
  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * ����������
   *****************************************************************************
   */
	public void initDetails( )
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");
    initSalesPlanSearchVo();
    XxcsoUtils.debug(getOADBTransaction(), "[END]");
  }
  
  /*****************************************************************************
   * �i�ށiCSV�쐬�j�{�^������������
   *****************************************************************************
   */
  public void handleCsvCreateButton()
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // ������񃊁[�W����
    XxcsoSalesPlanSearchVOImpl searchVo = getXxcsoSalesPlanSearchVO1();
    if ( searchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesPlanSearchVO1mpl");
    }

    // ������񃊁[�W�����s�C���X�^���X
    XxcsoSalesPlanSearchVORowImpl searchRowVo =
      (XxcsoSalesPlanSearchVORowImpl) searchVo.first();
    if ( searchRowVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesPlanSearchVORowImpl");
    }

    // ���_�R�[�h�A�N�x�̓��̓`�F�b�N
    this.validation(searchRowVo);

    // CSV�f�[�^�쐬
    this.makeCsvData(searchRowVo);

    XxcsoUtils.debug(getOADBTransaction(), "[END]");
  }

  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * ����v�挟����񃊁[�W���������ݒ�VO������
   *****************************************************************************
   */
  private void initSalesPlanSearchVo()
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");
    XxcsoSalesPlanSearchVOImpl searchVo = getXxcsoSalesPlanSearchVO1();
    if ( searchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesPlanSearchVO1mpl");
    }
    searchVo.executeQuery();
    XxcsoUtils.debug(getOADBTransaction(), "[END]");
  }

  /*****************************************************************************
   * �N�x�A���_�R�[�h���̓`�F�b�N
   * @param  searchRowVo
   * @throw  OAException �K�{���ڃG���[�A�Ó����`�F�b�N
   *****************************************************************************
   */
  private void validation(XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // ���_�R�[�h�|�K�{�`�F�b�N
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    List errorList = new ArrayList();
    errorList
      = util.requiredCheck(
          errorList
         ,searchRowVo.getBaseCode()
         ,XxcsoSalesPlanConstants.MSG_DISP_BASECODE
         ,0
        );
        
    // �N�x�|�K�{�{�Ó����`�F�b�N�i�S�������j
    errorList
      = util.checkStringToNumber(
          errorList
         ,searchRowVo.getBusinessYear()
         ,XxcsoSalesPlanConstants.MSG_DISP_BIZYEAR
         ,0
         ,4
         ,false
         ,false
         ,true
         ,0
        );

    if ( errorList.size () > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    XxcsoUtils.debug(txn, "[END]");
    return;
  }

  /*****************************************************************************
   * CSV�f�[�^(Excel�o�[�W����)�擾
   *****************************************************************************
   */
  private StringBuffer getCsvDataExcelVer()
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // �v���t�@�C���̎擾
    OADBTransaction txn  = getOADBTransaction();
    String verRoute = 
      txn.getProfile(XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_ROUTE);
    if ( verRoute == null || "".equals(verRoute.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_ROUTE
        );
    }
    String verHonbu = 
      txn.getProfile(XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_HONBU);
    if ( verHonbu == null || "".equals(verHonbu.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_HONBU
        );
    }


    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    // CSV�f�[�^
    return 
      new StringBuffer(
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        verRoute + 
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        XxcsoSalesPlanConstants.CSV_ITEM_DELIMITER + 
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        verHonbu + 
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        XxcsoSalesPlanConstants.CSV_CRLF);
  }

  /*****************************************************************************
   * CSV�f�[�^(���_��)�擾
   *****************************************************************************
   */
  private StringBuffer getCsvDataBasePlan(
    XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // ���_��VO
    XxcsoCreateBasePlanCsvVOImpl baseVo = getXxcsoCreateBasePlanCsvVO1();
    if ( baseVo == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoCreateBasePlanCsvVOImpl");
    }

    // CallableStatement�擾
    OADBTransaction         txn  = getOADBTransaction();
    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;
    stmt = 
      (OracleCallableStatement) txn.
        createCallableStatement(baseVo.getQuery(), 0);

    // ���_�ʃo�b�t�@
    StringBuffer csvData = new StringBuffer();
    try
    {
      // �o�C���h�ւ̒l�̐ݒ�AResultSet�擾
      stmt.setString(1, searchRowVo.getBusinessYear()); // �N�x
      stmt.setString(2, searchRowVo.getBaseCode()); 	// ���_�R�[�h
      stmt.setString(3, searchRowVo.getBaseCode()); 	// ���_�R�[�h
      rs = (OracleResultSet)stmt.executeQuery();

      // ResultSet���[�v
      while (rs.next())
      {
        // ResultSe���ڎ擾
      	for (int i = 1; i <= XxcsoSalesPlanConstants.CSV_MAX_ITEM_ID; i++)
      	{
  	      if (i > 1) 
          {
            csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_DELIMITER);
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
          if (i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_CODE)
          {
            csvData.append(searchRowVo.getBaseCode());
          }
          else if(i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_NAME)
          {
            csvData.append(searchRowVo.getBaseName());
          }
          else
          {
            if (rs.getString(i) != null)
            {
              csvData.append((String)rs.getString(i));
            }
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
        }
        csvData.append(XxcsoSalesPlanConstants.CSV_CRLF);
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
        );
    }
    finally
    {
      try
      {
        if ( rs != null )
        {
          rs.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
            ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
          );
      }
    }

    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    // CSV�f�[�^
    return csvData;
  }
  
  /*****************************************************************************
   * CSV�f�[�^(�c�ƈ���)�擾
   *****************************************************************************
   */
  private StringBuffer getCsvDataSalesPerson(
    XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // �c�ƈ���VO
    XxcsoCreateSalesPersonCsvVOImpl personVo = 
      getXxcsoCreateSalesPersonCsvVO1();
    if ( personVo == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoCreateSalesPersonCsvVOImpl");
    }
    // CallableStatement�擾
    OADBTransaction         txn  = getOADBTransaction();
    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;
    stmt = 
      (OracleCallableStatement) txn.
        createCallableStatement(personVo.getQuery(), 0);

    // ���_�ʃo�b�t�@
    StringBuffer csvData = new StringBuffer();
    try
    {
      // �o�C���h�ւ̒l�̐ݒ�AResultSet�擾
      stmt.setString(1, searchRowVo.getBaseCode()); 	// ���_�R�[�h
      stmt.setString(2, searchRowVo.getBaseCode()); 	// ���_�R�[�h
      stmt.setString(3, searchRowVo.getBusinessYear()); // �N�x
      stmt.setString(4, searchRowVo.getBaseCode()); 	// ���_�R�[�h
      stmt.setString(5, searchRowVo.getBusinessYear()); // �N�x
      stmt.setString(6, searchRowVo.getBaseCode()); 	// ���_�R�[�h
      rs = (OracleResultSet)stmt.executeQuery();

      // ResultSet���[�v
      while (rs.next())
      {
        // ResultSe���ڎ擾
      	for (int i = 1; i <= XxcsoSalesPlanConstants.CSV_MAX_ITEM_ID; i++)
      	{
  	      if (i > 1) 
          {
            csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_DELIMITER);
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
          if (i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_CODE)
          {
            csvData.append(searchRowVo.getBaseCode());
          }
          else if(i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_NAME)
          {
            csvData.append(searchRowVo.getBaseName());
          }
          else
          {
            if (rs.getString(i) != null)
            {
              csvData.append((String)rs.getString(i));
            }
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
        }
        csvData.append(XxcsoSalesPlanConstants.CSV_CRLF);
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
        );
    }
    finally
    {
      try
      {
        if ( rs != null )
        {
          rs.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
            ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
          );
      }
    }

    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    // CSV�f�[�^
    return csvData;

  }
  
  /*****************************************************************************
   * CSV�f�[�^�o��
   *****************************************************************************
   */
  private void makeCsvData(XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    // CSV�f�[�^�������� Start
    OADBTransaction txn  = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // �v���t�@�C���̎擾
    String clientEnc = txn.getProfile(XxcsoConstants.XXCSO1_CLIENT_ENCODE);
    if ( clientEnc == null || "".equals(clientEnc.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.XXCSO1_CLIENT_ENCODE
        );
    }

    // �t�@�C���_�E�����[�hVO�C���X�^���X
    XxcsoCsvDownVOImpl csvVo = getXxcsoCsvDownVO1();
    if ( csvVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVOImpl");
    }

    // �t�@�C���_�E�����[�h�sVO�C���X�^���X
    XxcsoCsvDownVORowImpl csvRowVo
      = (XxcsoCsvDownVORowImpl)csvVo.createRow();
    if ( csvRowVo == null )
    {
        throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVORowImpl");
    }

    // �t�@�C�����擾
    String sbFileName = getFileName(searchRowVo);
    
    // CSV�f�[�^�擾
    StringBuffer sbFileData = getCsvDataExcelVer();
    int verLen = sbFileData.length();
    sbFileData.append(getCsvDataBasePlan(searchRowVo));
    sbFileData.append(getCsvDataSalesPerson(searchRowVo));

    // �Ώۃf�[�^�Ȃ�
    if ( verLen == sbFileData.length() )
    {
      // �G���[�F�Ώۃf�[�^�Ȃ�
      throw
        XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00454
        );
    }

    try
    {
      // �t�@�C�����A�t�@�C���f�[�^����ݒ�
      csvRowVo.setBusinessYear(searchRowVo.getBusinessYear());
      csvRowVo.setBaseName(searchRowVo.getBaseName());
      csvRowVo.setFileName(sbFileName);
      csvRowVo.setFileData(
        new BlobDomain(sbFileData.toString().getBytes(clientEnc))
      );
    }
    catch (UnsupportedEncodingException uae)
    {
      throw
          XxcsoMessage.createCsvErrorMessage(uae);
    }

    // VO�ɏo��
    csvVo.last();
    csvVo.next();
    csvVo.insertRow(csvRowVo);

    // �������b�Z�[�W��ݒ肷��
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoSalesPlanConstants.MSG_DISP_CSV);
    sbMsg.append(sbFileName);

    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoSalesPlanConstants.MSG_DISP_OUT
        );
        
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �t�@�C�����擾
   *****************************************************************************
   */
  private String getFileName(XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    OADBTransaction txn  = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // CSV�t�@�C�����̐���(���_�R�[�h_�N�x_download_yyyymmddhh24miss.csv)
    StringBuffer sbFileName = new StringBuffer(120);
    sbFileName.append(searchRowVo.getBaseCode());
    sbFileName.append(XxcsoSalesPlanConstants.CSV_NAME_DELIMITER);
    sbFileName.append(searchRowVo.getBusinessYear());
    sbFileName.append(XxcsoSalesPlanConstants.CSV_NAME_KEY);
    sbFileName.append(XxcsoAcctSalesPlansUtils.getSysdateTimeString(txn));
    sbFileName.append(XxcsoSalesPlanConstants.CSV_EXTENSION);

    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    return sbFileName.toString();
  }
  
  /*****************************************************************************
   * OAF Auto Generate
   *****************************************************************************
   */
  /**
   * 
   * Container's getter for XxcsoCreateBasePlanCsvVO1
   */
  public XxcsoCreateBasePlanCsvVOImpl getXxcsoCreateBasePlanCsvVO1()
  {
    return (XxcsoCreateBasePlanCsvVOImpl)findViewObject("XxcsoCreateBasePlanCsvVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCreateSalesPersonCsvVO1
   */
  public XxcsoCreateSalesPersonCsvVOImpl getXxcsoCreateSalesPersonCsvVO1()
  {
    return (XxcsoCreateSalesPersonCsvVOImpl)findViewObject("XxcsoCreateSalesPersonCsvVO1");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso001001j.server", "XxcsoSalesPlanOutAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoCsvDownVO1
   */
  public XxcsoCsvDownVOImpl getXxcsoCsvDownVO1()
  {
    return (XxcsoCsvDownVOImpl)findViewObject("XxcsoCsvDownVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesPlanSearchVO1
   */
  public XxcsoSalesPlanSearchVOImpl getXxcsoSalesPlanSearchVO1()
  {
    return (XxcsoSalesPlanSearchVOImpl)findViewObject("XxcsoSalesPlanSearchVO1");
  }


}