/*============================================================================
* �t�@�C���� : XxinvFileUploadAMImpl.java
* �T�v����   : �t�@�C���A�b�v���[�h�A�v���P�[�V�������W���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-23 1.0  ������j      �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv990001j.server;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * �t�@�C���A�b�v���[�h�A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE ������j
 * @version 1.0
 ***************************************************************************
 */
public class XxinvFileUploadAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvFileUploadAMImpl()
  {
  }

  /**
   * �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�e�[�u�����R�[�h�쐬�B
   */
  public void createXxinvMrpFileUlInterfaceRec()
  {
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxinvMrpFileUlInterfaceVO1();
    if (!vo.isPreparedForExecution())
    {
      vo.executeQuery();
    }
    // �V�K�s���쐬����B
    OARow row = (OARow)vo.createRow();
    vo.insertRow(row);
  }

  /**
   * �f�[�^�x�[�X�ƒ��ԑw�����[���o�b�N����B
   */
  public void rollbackXxinvMrpFileUlInterface()
  {
    OADBTransaction txn = getOADBTransaction();
    if (txn.isDirty())
    {
      txn.rollback();
    }
  }

  /**
   * �g�����U�N�V�����̃R�~�b�g�B
   */
  public void apply()
  {
    getTransaction().commit();
  }

  /**
    * �A�b�v���[�h�t�@�C�����ݒ�B
    * @param fileName �A�b�v���[�h�t�@�C����
    * @param conType  �A�b�v���[�h�t�@�C���R���e���g�^�C�v
    */
  public void setUlFileInfo(
    String fileName, 
    String conType)
  {
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxinvMrpFileUlInterfaceVO1();
    OARow row = (OARow)vo.getCurrentRow();
    row.setAttribute("FileName", fileName);
    row.setAttribute("FileContentType", conType);
      
  }

  /**
   * �Q�ƃ^�C�v���A�R���J�����g���̂���уt�H�[�}�b�g�p�^�[�����擾����B
   * @param lookuptype - �^�C�v
   * @param conType - �R�[�h(�R���e���g�^�C�v�R�[�h)
   * @return String - Meaning
   */
  public String getLookUpValue(String lookuptype, String conType)
  {
    XxinvLookUpValueVOImpl vo = getXxinvLookUpValueVO1();
    vo.getLookUpValue(lookuptype, conType);
    OARow row = (OARow)vo.first();
    return (String)row.getAttribute("Meaning");
  }

  /**
   * �A�b�v���[�h�R���J�����g�̋N���B
   * @param concName - �R���J�����g����
   * @param formatPattern - �t�H�[�}�b�g�p�^�[��
   * @return long - �v��id
   */
  public long concRun(
    String concName, 
    String formatPattern)
  {
    // �X�g�A�h�v���V�[�W�������s�����邽�߂̃C���^�[�t�F�[�X
    CallableStatement stmt = null;
    try
    {
      // �t�@�C��ID�̎擾
      OAViewObjectImpl vo = (OAViewObjectImpl)getXxinvMrpFileUlInterfaceVO1();
      OARow row = (OARow)vo.getCurrentRow();
      Number fileId = (Number)row.getAttribute("FileId");
      // �g�����U�N�V�����̎擾
      OADBTransaction trans = getOADBTransaction();
      // �v���V�[�W��
      StringBuffer sb = new StringBuffer(100);
      sb.append("BEGIN ");
      sb.append("  fnd_global.apps_initialize(:1, :2, :3); ");
      sb.append("  :4 := fnd_request.submit_request( ");
      sb.append("          'XXINV'  ");
      sb.append("         , :5      ");
      sb.append("         , NULL    ");
      sb.append("         , SYSDATE ");
      sb.append("         , FALSE   ");
      sb.append("         , :6      ");
      sb.append("         , :7 );   ");
      sb.append("END; ");
      stmt = trans.createCallableStatement(sb.toString(), 0);
      // �o�C���h�ϐ��ɒl���Z�b�g����
      stmt.setInt(1, trans.getUserId());
      stmt.setInt(2, trans.getResponsibilityId());
      stmt.setInt(3, trans.getResponsibilityApplicationId());
      stmt.registerOutParameter(4, Types.BIGINT);
      stmt.setString(5, "" + concName);
      stmt.setLong(6, fileId.longValue());
      stmt.setString(7, "" + formatPattern);

      // �v���V�[�W���̎��s
      stmt.execute();
      return stmt.getLong(4);
    } catch(SQLException e)
    {
      // ���O�o��
      XxcmnUtility.writeLog(getOADBTransaction(),
                          getClass().getName() + 
                          XxcmnConstants.DOT + "concRun",
                          e.toString(),
                          6);
      throw OAException.wrapperException(e);
    } finally
    {
      if (stmt != null)
      {
        try
        {
          stmt.close();
        } catch (SQLException e2)
        {
          // ���O�o��
          XxcmnUtility.writeLog(getOADBTransaction(),
                                getClass().getName() + 
                                XxcmnConstants.DOT + "concRun",
                                e2.toString(),
                                6);
          throw OAException.wrapperException(e2);
        }
      }
    }
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxinv.xxinv990001j.server", "XxinvFileUploadAMLocal");
  }


  /**
   * 
   * Container's getter for XxinvLookUpValueVO1
   */
  public XxinvLookUpValueVOImpl getXxinvLookUpValueVO1()
  {
    return (XxinvLookUpValueVOImpl)findViewObject("XxinvLookUpValueVO1");
  }

  /**
   * 
   * Container's getter for XxinvMrpFileUlInterfaceVO1
   */
  public OAViewObjectImpl getXxinvMrpFileUlInterfaceVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxinvMrpFileUlInterfaceVO1");
  }

}