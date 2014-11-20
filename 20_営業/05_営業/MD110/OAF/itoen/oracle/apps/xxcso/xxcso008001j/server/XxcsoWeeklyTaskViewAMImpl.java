/*============================================================================
* �t�@�C���� : XxcsoWeeklyTaskViewImpl
* �T�v����   : �T�������󋵏Ɖ�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;

import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso008001j.util.XxcsoWeeklyTaskViewConstants;
import java.sql.SQLException;
import java.io.UnsupportedEncodingException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;

/*******************************************************************************
 * �T�������󋵏Ɖ��ʂ̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoWeeklyTaskViewAMImpl extends OAApplicationModuleImpl 
{

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoWeeklyTaskViewAMImpl()
  {
  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * ����������
   *****************************************************************************
   */
  public void initDetails()
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �X�P�W���[���w�胊�[�W�����̃C���X�^���X
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    if ( ! taskAppSchVo.isPreparedForExecution() )
    {
      // �������������s
      taskAppSchVo.executeQuery();

      // ****************************************
      // *****�����ݒ�pVO�̏�����***************
      // ****************************************
      // �S���ґI�����[�W�����̑����pVO
      this.initEmpSelRender();

      // �X�P�W���[�����[�W�����̑����pVO
      this.initTaskRender();

      // ****************************************
      // *****�����ݒ�pVO�̐ݒ�*****************
      // ****************************************
      // �S���ґI�����[�W�����̑����ݒ�
      this.setEmpSelItemAttribute(false);

      // �X�P�W���[�����[�W�����̑����ݒ�
      this.setTaskItemAttribute(0);

    XxcsoUtils.debug(txt, "[END]");

    }
  }

  /*****************************************************************************
   * �����������i�\���{�^���j
   *****************************************************************************
   */
  public void initAfterHandleShowButton(
    String  txnKey1
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // �X�P�W���[���w�胊�[�W�����̃C���X�^���X
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // �S���ґI�����[�W�����̃C���X�^���X
    XxcsoEmpSelSummaryVOImpl empSelVo = getXxcsoEmpSelSummaryVO1();
    if ( empSelVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelSummaryVOImpl");
    }

    // ���_����VO�C���X�^���X
    XxcsoBaseSearchVOImpl baseSchVo = getXxcsoBaseSearchVO1();
    if ( baseSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoBaseSearchVOImpl");
    }
    
    if ( ! taskAppSchVo.isPreparedForExecution() )
    {
      // �������������s
      taskAppSchVo.executeQuery();

      // ****************************************
      // *****�����ݒ�pVO�̏�����***************
      // ****************************************
      // �S���ґI�����[�W�����̑����pVO
      this.initEmpSelRender();

      // �X�P�W���[�����[�W�����̑����pVO
      this.initTaskRender();

      // ****************************************
      // *****�����ݒ�pVO�̐ݒ�*****************
      // ****************************************
      // �S���ґI�����[�W�����̑����ݒ�
      this.setEmpSelItemAttribute(false);

      // �X�P�W���[�����[�W�����̑����ݒ�
      this.setTaskItemAttribute(0);

      // �g�����U�N�V�����L�[���l�𒊏o
      String[] values = txnKey1.split("\\|");

      for ( int i = 0; i < values.length; i++ )
      {
        XxcsoUtils.debug(txn, "transaction value[" + i + "]" + values[i]);
      }
      
      Date dateSch = new Date(values[0]);
      String baseCodeSch = values[1];

      baseSchVo.initQuery(baseCodeSch);
      XxcsoBaseSearchVORowImpl baseSchRow
        = (XxcsoBaseSearchVORowImpl)baseSchVo.first();
      String baseNameSch = baseSchRow.getBaseName();

      // ���t�E������ݒ�
      XxcsoTaskAppSearchVORowImpl taskAppSchRow
        = (XxcsoTaskAppSearchVORowImpl)taskAppSchVo.first();
      taskAppSchRow.setDateSch(dateSch);
      taskAppSchRow.setBaseCode(baseCodeSch);
      taskAppSchRow.setBaseName(baseNameSch);

      // �i�ރ{�^�����������������s
      handleForwardButton();

      // �S���ґI�����[�W�����̃`�F�b�N�{�b�N�X��ݒ�
      XxcsoEmpSelSummaryVORowImpl empSelRow
        = (XxcsoEmpSelSummaryVORowImpl)empSelVo.first();

      while( empSelRow != null )
      {
        String userId = empSelRow.getUserId().stringValue();
        
        for ( int i = 2; i < values.length; i++ )
        {
          if ( userId.equals(values[i]) )
          {
            empSelRow.setSelectFlg("Y");
            break;
          }
        }
        
        empSelRow = (XxcsoEmpSelSummaryVORowImpl)empSelVo.next();
      }

      // �I�����ꂽ���[�U�[�̃^�X�N�\��
      // �I��l�i�[�pList(�ő�10���̂���10�ŏ�����)
      List chkdList = new ArrayList(10);

      empSelRow = (XxcsoEmpSelSummaryVORowImpl)empSelVo.first();
      while ( empSelRow != null )
      {
        // �I��CheckBox=ON�̃I�u�W�F�N�g�𒊏o
        if( "Y".equals(empSelRow.getSelectFlg()) )
        {
          // �s����map�Ɋi�[���A��񒊏o�plist��
          Map lineMap = new HashMap(2);
          lineMap.put(
            XxcsoWeeklyTaskViewConstants.RESOURCE_ID
            ,empSelRow.getResourceId()
          );
          lineMap.put(
            XxcsoWeeklyTaskViewConstants.EMP_NAME
            ,empSelRow.getFullName()
          );

          chkdList.add(lineMap);
        }
        empSelRow = (XxcsoEmpSelSummaryVORowImpl)empSelVo.next();
      }

      // �X�P�W���[�����[�W�����\��
      this.createTaskInfo(dateSch, chkdList);
      // �X�P�W���[�����[�W�����̑����ݒ���s��
      this.setTaskItemAttribute(chkdList.size());

    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * �i�ރ{�^������������
   *****************************************************************************
   */
  public void handleForwardButton()
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �X�P�W���[���w�胊�[�W�����̃C���X�^���X
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // �X�P�W���[���w�胊�[�W�����s�C���X�^���X
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    // �����̓��̓`�F�b�N�����A�����Ώۂ̋��_�R�[�h���擾
    String baseCodeSch = this.chkBaseName(taskAppSchVoRow);

    // �S���ґI�����[�W�����̃C���X�^���X
    XxcsoEmpSelSummaryVOImpl empSelVo = getXxcsoEmpSelSummaryVO1();
    if ( empSelVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelSummaryVOImpl");
    }
    // �S���ґI�����[�W����Query���s
    empSelVo.initQuery(baseCodeSch);

    // �����`�F�b�N(first��null�`�F�b�N)
    XxcsoEmpSelSummaryVORowImpl empSelVoRow =
      (XxcsoEmpSelSummaryVORowImpl) empSelVo.first();
    if ( empSelVoRow != null )
    {
      // 1���ȏ�Ȃ�Ε\���{�^���\��
      this.setEmpSelItemAttribute(true);
    }
    else
    {
      // ��L�ȊO�͔�\��
      this.setEmpSelItemAttribute(false);
    }

    // �X�P�W���[���\�����[�W���������ݒ�(�i�ރ{�^�������ŏ�����)
    this.setTaskItemAttribute(0);

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * CSV�쐬�{�^������������
   *****************************************************************************
   */
  public void handleCsvCreateButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �X�P�W���[���w�胊�[�W�����̃C���X�^���X
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // �X�P�W���[���w�胊�[�W�����s�C���X�^���X
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    // �w����t�̎擾
    Date dateSch = taskAppSchVoRow.getDateSch();

    // �w����t�̓��̓`�F�b�N
    this.chkAppDate(dateSch);

    // �����̓��̓`�F�b�N�����A�����Ώۂ̋��_�R�[�h���擾
    String baseCodeSch = this.chkBaseName(taskAppSchVoRow);

    // CSV���sSQL�i�[VO���ASQL�����擾
    XxcsoCsvQueryVOImpl csvQueryVo = getXxcsoCsvQueryVO1();
    if (csvQueryVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvQueryVOImpl");
    }
    String csvQuery = csvQueryVo.getQuery();

    // ****************************************
    // *****CSV�f�[�^�������� Start************
    // ****************************************
    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;

    // �v���t�@�C���̎擾
    String clientEnc = txt.getProfile(XxcsoConstants.XXCSO1_CLIENT_ENCODE);
    if ( clientEnc == null || "".equals(clientEnc.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.XXCSO1_CLIENT_ENCODE
        );
    }

    // CallableStatement�ɂ��Query���s
    stmt = (OracleCallableStatement) txt.createCallableStatement(csvQuery, 0);

    StringBuffer sbFileData = new StringBuffer();
    try
    {
      // �o�C���h�ւ̒l�̐ݒ�
      int idx = 1;
      stmt.setString(idx++, baseCodeSch); // ���_�R�[�h
      stmt.setString(idx++, baseCodeSch); // ���_�R�[�h
      stmt.setString(idx++, baseCodeSch); // ���_�R�[�h
      stmt.setString(idx++, dateSch.dateValue().toString()); // ���t
      stmt.setString(idx++, dateSch.dateValue().toString()); // ���t
      stmt.setString(idx++, dateSch.dateValue().toString()); // ���t

      rs = (OracleResultSet)stmt.executeQuery();

      while (rs.next())
      {
        // �o�͗p�o�b�t�@�֊i�[
        int rsIdx = 1;
        // ����:�]�ƈ��ԍ�
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // ����:�S���Җ�
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // ����:����
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // ����:�j��
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // ����:�\��^����
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // ����:�^�X�N�ڍ�
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append("\n");
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txt, e);

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
        XxcsoUtils.unexpected(txt, e);

        throw
          XxcsoMessage.createSqlErrorMessage(
            e
            ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
          );
      }
    }
    // ****************************************
    // *****CSV�f�[�^�������� End**************
    // ****************************************

    // VO�ւ̃t�@�C�����A�t�@�C���f�[�^�̐ݒ�
    XxcsoCsvDownVOImpl csvVo = getXxcsoCsvDownVO1();
    if ( csvVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVOImpl");
    }

    XxcsoCsvDownVORowImpl csvRowVo
      = (XxcsoCsvDownVORowImpl)csvVo.createRow();

    // *****CSV�t�@�C�����p���t������(yyyymmdd)
    StringBuffer sbDate = new StringBuffer(8);
    String nowDate = txt.getCurrentUserDate().dateValue().toString();
    sbDate.append(nowDate.substring(0, 4));
    sbDate.append(nowDate.substring(5, 7));
    sbDate.append(nowDate.substring(8, 10));

    // *****CSV�t�@�C�����̐���(���[�U�[��_yyyymmdd_�A��)
    StringBuffer sbFileName = new StringBuffer(120);
    sbFileName.append(txt.getUserName());
    sbFileName.append(XxcsoWeeklyTaskViewConstants.CSV_NAME_DELIMITER);
    sbFileName.append(sbDate);
    sbFileName.append(XxcsoWeeklyTaskViewConstants.CSV_NAME_DELIMITER);
    sbFileName.append((csvVo.getRowCount() + 1));
    sbFileName.append(XxcsoWeeklyTaskViewConstants.CSV_EXTENSION);

    try
    {
      // *****�t�@�C�����A�t�@�C���f�[�^��ݒ�
      csvRowVo.setFileName(new String(sbFileName));
      csvRowVo.setFileData(
        new BlobDomain(sbFileData.toString().getBytes(clientEnc))
      );
    }
    catch (UnsupportedEncodingException uae)
    {
      throw
          XxcsoMessage.createCsvErrorMessage(uae);
    }

    csvVo.last();
    csvVo.next();
    csvVo.insertRow(csvRowVo);

    // �������b�Z�[�W��ݒ肷��
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoWeeklyTaskViewConstants.MSG_DISP_CSV);
    sbMsg.append(sbFileName);

    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoWeeklyTaskViewConstants.MSG_DISP_OUT
        );

    XxcsoUtils.debug(txt, "[END]");

    return;
  }

  /*****************************************************************************
   * �\���{�^������������
   * @throw OAException �S���Җ��I���G���[
   *                     �S���Ғ��߃G���[
   *****************************************************************************
   */
  public String handleShowButton()
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �X�P�W���[���w�胊�[�W�����̃C���X�^���X
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // �X�P�W���[���w�胊�[�W�����s�C���X�^���X
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    // �S���ґI�����[�W�����̃C���X�^���X
    XxcsoEmpSelSummaryVOImpl empSelVo = getXxcsoEmpSelSummaryVO1();
    if ( empSelVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelSummaryVOImpl");
    }

    // �w����t�̎擾
    Date dateSch = taskAppSchVoRow.getDateSch();
    // ���_�R�[�h�̎擾
    String baseCodeSch = taskAppSchVoRow.getBaseCode();
    
    // �w����t�̓��̓`�F�b�N
    this.chkAppDate(dateSch);


    // �S���ґI�����[�W�����̍s�C���X�^���X
    XxcsoEmpSelSummaryVORowImpl empSelVoRow =
      (XxcsoEmpSelSummaryVORowImpl) empSelVo.first();

    // �I��l�i�[�pList(�ő�10���̂���10�ŏ�����)
    List chkdList = new ArrayList(10);

    int chkCnt = 0;
    
    // �S�s��Fetch
    while ( empSelVoRow != null )
    {
      // �I��CheckBox=ON�̃I�u�W�F�N�g�𒊏o
      if( "Y".equals(empSelVoRow.getSelectFlg()) )
      {
        chkCnt++;
        
        // �S���ґI�𒴉߃`�F�b�N
        if ( chkCnt > XxcsoWeeklyTaskViewConstants.MAX_SIZE_INT ) 
        {
          // �S���ґI�𒴉߃G���[
          throw
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00047
              ,XxcsoConstants.TOKEN_ITEM
              ,XxcsoWeeklyTaskViewConstants.MSG_DISP_EMPSEL
              ,XxcsoConstants.TOKEN_SIZE
              ,XxcsoWeeklyTaskViewConstants.MAX_SIZE_STR
            );
        }
        // ���[�U�[ID��ޔ�
        chkdList.add(empSelVoRow.getUserId().stringValue());

      }
      
      empSelVoRow = (XxcsoEmpSelSummaryVORowImpl) empSelVo.next();
    }

    // �I���`�F�b�N(���߃`�F�b�N�͏㏈��while���ɂĎ��{)
    if ( chkCnt == 0 )
    {
      // �S���Җ��I���G���[
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00229);
    }

    StringBuffer urlParam = new StringBuffer(100);
    urlParam.append(dateSch.toString());
    urlParam.append("|").append(baseCodeSch);
    for ( int i = 0; i < chkdList.size(); i++ )
    {
      urlParam.append("|").append((String)chkdList.get(i));
    }

    XxcsoUtils.debug(txt, "URL PARAMETER = " + urlParam.toString());
    
    XxcsoUtils.debug(txt, "[END]");

    return urlParam.toString();
  }

  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");
    XxcsoUtils.debug(txt, "[END]");

    return mMessage;

  }

  /*****************************************************************************
   * ���O�C�����[�U�[�̃��\�[�XID���擾���܂�
   * @return ���O�C�����[�U�[�̃��[�\�[�XID
   *****************************************************************************
   */
  public String getLoginResourceId()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // �X�P�W���[���w�胊�[�W�����̃C���X�^���X
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // �X�P�W���[���w�胊�[�W�����s�C���X�^���X
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    Number loginResourceId = taskAppSchVoRow.getLoginResourceId();
    if ( loginResourceId == null)
    {
      // ���\�[�XID���ݒ莞�̓G���[�Ƃ���
      throw
        XxcsoMessage.createErrorMessage( XxcsoConstants.APP_XXCSO1_00546 );
    }

    XxcsoUtils.debug(txt, "[END]");

    return loginResourceId.toString();
  }

  /*****************************************************************************
   * �w����t���̓`�F�b�N
   * @param  date �w����t
   * @throw  OAException ���t���w��G���[
   *****************************************************************************
   */
  private void chkAppDate(Date date)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    if ( date == null || "".equals(date) )
    {
      // �G���[�F���t���w��
      throw
        XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00005
              ,XxcsoConstants.TOKEN_COLUMN
              ,XxcsoWeeklyTaskViewConstants.MSG_DISP_DATE
        );
    }

    XxcsoUtils.debug(txt, "[END]");

    return;
  }

  /*****************************************************************************
   * ���������̓`�F�b�N
   * @param taskSumVoRow �X�P�W���[���w�胊�[�W������VO�s�C���X�^���X
   * @return �����Ώۂ̋��_�R�[�h
   *****************************************************************************
   */
  private String chkBaseName(XxcsoTaskAppSearchVORowImpl taskAppSchVoRow)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    String retBaseCode = "";

    String inpBaseName = taskAppSchVoRow.getBaseName();
    if ( inpBaseName == null || "".equals(inpBaseName.trim()) )
    {
      // �����͎��̓��O�C�����[�U�[�̊�Ζ��拒�_�R�[�h����擾
      retBaseCode = taskAppSchVoRow.getBaseLineBaseCode(); 
    }
    else
    {
      // ���͎��͕����I��LOV�őI�����ꂽ�l����擾
      retBaseCode = taskAppSchVoRow.getBaseCode();
    }

    XxcsoUtils.debug(txt, "[END]");

    return retBaseCode;
  }

  /*****************************************************************************
   * �X�P�W���[�����[�W�������e�쐬
   * @param appDate �X�P�W���[���w�胊�[�W�����̓��t
   * @param list    �S���I�����[�W�����I�����ڂ�List<Map>
   *****************************************************************************
   */
  private void createTaskInfo(
     Date  appDate
    ,List  list
    )
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    int size = list.size();
    int instCnt = 0;
    for ( int i = 0; i < size; i++ )
    {
      Map map = (HashMap)list.get(i);
      instCnt = i + 1;
      
      // �X�P�W���[���i�S���ҁj�̕\��
      XxcsoEmpNameSummaryVOImpl empNameVo = (XxcsoEmpNameSummaryVOImpl)
        findViewObject("XxcsoEmpNameSummaryVO" + instCnt);
      if ( empNameVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoEmpNameSummaryVO" + instCnt);
      }
      empNameVo.initQuery(
        (String) map.get(XxcsoWeeklyTaskViewConstants.EMP_NAME)
      );

      // �X�P�W���[���i�X�P�W���[���j�̕\��
      XxcsoTaskSummaryVOImpl taskSumVo = (XxcsoTaskSummaryVOImpl)
        findViewObject("XxcsoTaskSummaryVO" + instCnt);
      if ( taskSumVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskSummaryVO" + instCnt);
      }
      taskSumVo.initQuery(
        appDate.dateValue().toString(),
        (Number) map.get(XxcsoWeeklyTaskViewConstants.RESOURCE_ID)
      );
    }

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * �S���ґI�����[�W���������ݒ�VO������
   *****************************************************************************
   */
  private void initEmpSelRender()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoEmpSelRenderVOImpl renderVo = getXxcsoEmpSelRenderVO1();
    if ( renderVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelRenderVOImpl");
    }
    renderVo.executeQuery();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * �S���ґI�����[�W���������ݒ�
   * @param isRender true:�\���Afalse:��\��
   *****************************************************************************
   */
  private void setEmpSelItemAttribute(boolean isRender)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoEmpSelRenderVOImpl renderVo = getXxcsoEmpSelRenderVO1();
    if ( renderVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelRenderVOImpl");
    }

    XxcsoEmpSelRenderVORowImpl renderVoRow =
      (XxcsoEmpSelRenderVORowImpl) renderVo.first();
    if ( renderVoRow == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoEmpSelRenderVORowImpl");
    }

    if ( isRender )
    {
      renderVoRow.setEmpSelRender(Boolean.TRUE);
    }
    else
    {
      renderVoRow.setEmpSelRender(Boolean.FALSE);
    }

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * �X�P�W���[�����[�W���������ݒ�VO������
   *****************************************************************************
   */
  private void initTaskRender()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    int instCnt = 0;
    for ( int i = 0; i < XxcsoWeeklyTaskViewConstants.MAX_SIZE_INT; i++ )
    {
      instCnt = i + 1;

      XxcsoTaskRenderVOImpl renderVo = (XxcsoTaskRenderVOImpl)
        findViewObject("XxcsoTaskRenderVO" + instCnt);
      if ( renderVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVO" + instCnt);
      }

      renderVo.executeQuery();
    }

    XxcsoUtils.debug(txt, "[END]");

  }
  /*****************************************************************************
   * �X�P�W���[���̕\��������ݒ肵�܂��B
   * @param setSize �ݒ�ς݂̍s�J�E���g
   *****************************************************************************
   */
  private void setTaskItemAttribute(int setSize)
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // ****************************************
    // *****�\���\�X�P�W���[���̐ݒ�*********
    // ****************************************
    // �����̐ݒ�ςݍs����render=true�ɐݒ�
    int instCnt1 = 0;
    for (int i = 0; i < setSize; i++)
    {
      instCnt1 = i + 1;

      XxcsoTaskRenderVOImpl renderVo = (XxcsoTaskRenderVOImpl)
        findViewObject("XxcsoTaskRenderVO" + instCnt1);
      if ( renderVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVO" + instCnt1);
      }

      XxcsoTaskRenderVORowImpl renderVoRow =
        (XxcsoTaskRenderVORowImpl) renderVo.first();
      if ( renderVoRow == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVORow" + instCnt1);
      }
      renderVoRow.setTaskRender(Boolean.TRUE);
    }

    // ****************************************
    // *****�\���s�X�P�W���[���̐ݒ�*********
    // ****************************************
    // �����̐ݒ�ςݍs������n�܂�J�E���g��MAX_SIZE_INT�܂�render=false�ɐݒ�
    int instCnt2 = 0;
    for ( int j = setSize; j < XxcsoWeeklyTaskViewConstants.MAX_SIZE_INT; j++ )
    {
      instCnt2 = j + 1;

      XxcsoTaskRenderVOImpl renderVo = (XxcsoTaskRenderVOImpl)
        findViewObject("XxcsoTaskRenderVO" + instCnt2);
      if ( renderVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVO" + instCnt2);
      }

      XxcsoTaskRenderVORowImpl renderVoRow =
        (XxcsoTaskRenderVORowImpl) renderVo.first();
      if ( renderVoRow == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVORow" + instCnt1);
      }
      renderVoRow.setTaskRender(Boolean.FALSE);
    }

    XxcsoUtils.debug(txt, "[END]");

  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso008001j.server", "Xxcso008001jAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoEmpSelSummaryVO1
   */
  public XxcsoEmpSelSummaryVOImpl getXxcsoEmpSelSummaryVO1()
  {
    return (XxcsoEmpSelSummaryVOImpl)findViewObject("XxcsoEmpSelSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO1
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO1()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO2
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO2()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO2");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO3
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO3()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO3");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO4
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO4()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO4");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO5
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO5()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO5");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO6
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO6()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO6");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO7
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO7()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO7");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO8
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO8()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO8");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO9
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO9()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO9");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO10
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO10()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO10");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO1
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO1()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO2
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO2()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO2");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO3
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO3()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO3");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO4
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO4()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO4");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO5
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO5()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO5");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO6
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO6()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO6");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO7
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO7()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO7");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO8
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO8()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO8");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO9
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO9()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO9");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO10
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO10()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO10");
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
   * Container's getter for XxcsoTaskAppSearchVO1
   */
  public XxcsoTaskAppSearchVOImpl getXxcsoTaskAppSearchVO1()
  {
    return (XxcsoTaskAppSearchVOImpl)findViewObject("XxcsoTaskAppSearchVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO1
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO1()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO2
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO2()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO2");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO3
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO3()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO3");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO4
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO4()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO4");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO5
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO5()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO5");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO6
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO6()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO6");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO7
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO7()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO7");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO8
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO8()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO8");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO9
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO9()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO9");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO10
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO10()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO10");
  }

  /**
   * 
   * Container's getter for XxcsoCsvQueryVO1
   */
  public XxcsoCsvQueryVOImpl getXxcsoCsvQueryVO1()
  {
    return (XxcsoCsvQueryVOImpl)findViewObject("XxcsoCsvQueryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoEmpSelRenderVO1
   */
  public XxcsoEmpSelRenderVOImpl getXxcsoEmpSelRenderVO1()
  {
    return (XxcsoEmpSelRenderVOImpl)findViewObject("XxcsoEmpSelRenderVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBaseSearchVO1
   */
  public XxcsoBaseSearchVOImpl getXxcsoBaseSearchVO1()
  {
    return (XxcsoBaseSearchVOImpl)findViewObject("XxcsoBaseSearchVO1");
  }


}