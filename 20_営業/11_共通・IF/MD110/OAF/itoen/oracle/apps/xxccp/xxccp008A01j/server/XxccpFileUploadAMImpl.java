/*============================================================================
* �t�@�C���� : XxccpFileUploadAMImpl.java
* �T�v����   : �t�@�C���A�b�v���[�h�A�v���P�[�V�������W���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp008A01j.server;
import itoen.oracle.apps.xxccp.util.XxccpConstants;
import itoen.oracle.apps.xxccp.util.XxccpUtility2;
import itoen.oracle.apps.xxccp.util.server.XxccpOAApplicationModuleImpl;

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
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpFileUploadAMImpl extends XxccpOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpFileUploadAMImpl()
  {
  }

  /**
   * �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�e�[�u�����R�[�h�쐬�B
   */
  public void createXxccpMrpFileUlInterfaceRec()
  {
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxccpMrpFileUlInterfaceVO1();
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
  public void rollbackXxccpMrpFileUlInterface()
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
    OAViewObjectImpl vo = (OAViewObjectImpl)getXxccpMrpFileUlInterfaceVO1();
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
    XxccpLookUpValueVOImpl vo = getXxccpLookUpValueVO1();
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
      OAViewObjectImpl vo = (OAViewObjectImpl)getXxccpMrpFileUlInterfaceVO1();
      OARow row = (OARow)vo.getCurrentRow();
      Number fileId = (Number)row.getAttribute("FileId");
      // �g�����U�N�V�����̎擾
      OADBTransaction trans = getOADBTransaction();
      // �v���V�[�W��
      StringBuffer sb = new StringBuffer(100);
      sb.append("DECLARE ");
      sb.append("  lt_application_short_name  fnd_application.application_short_name%TYPE; ");
      sb.append("BEGIN ");
      sb.append("  SELECT fa.application_short_name              ");
      sb.append("  INTO   lt_application_short_name              ");
      sb.append("  FROM   fnd_concurrent_programs fcp            "); // �R���J�����g�v���O����
      sb.append("        ,fnd_application         fa             "); // �A�v���P�[�V����
      sb.append("  WHERE  fcp.application_id = fa.application_id ");
      sb.append("  AND    fcp.concurrent_program_name = :1       "); // �R���J�����g��
      sb.append("  AND    fcp.enabled_flag = 'Y';                "); // �L���t���O
      sb.append("  fnd_global.apps_initialize(:2, :3, :4); ");
      sb.append("  :5 := fnd_request.submit_request( ");
      sb.append("           lt_application_short_name  "); // �A�v���P�[�V�����Z�k��
      sb.append("         , :6      ");
      sb.append("         , NULL    ");
      sb.append("         , NULL ");
      sb.append("         , FALSE   ");
      sb.append("         , :7      ");
      sb.append("         , :8 );   ");
      sb.append("END; ");
      stmt = trans.createCallableStatement(sb.toString(), 0);
      // �o�C���h�ϐ��ɒl���Z�b�g����
      stmt.setString(1, "" + concName);
      stmt.setInt(2, trans.getUserId());
      stmt.setInt(3, trans.getResponsibilityId());
      stmt.setInt(4, trans.getResponsibilityApplicationId());
      stmt.registerOutParameter(5, Types.BIGINT);
      stmt.setString(6, "" + concName);
      stmt.setLong(7, fileId.longValue());
      stmt.setString(8, "" + formatPattern);
      // �v���V�[�W���̎��s
      stmt.execute();
      return stmt.getLong(5);
    } catch(SQLException e)
    {
      // ���O�o��
      XxccpUtility2.writeLog(getOADBTransaction(),
                          getClass().getName() + 
                          XxccpConstants.DOT + "concRun",
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
          XxccpUtility2.writeLog(getOADBTransaction(),
                                getClass().getName() + 
                                XxccpConstants.DOT + "concRun",
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
    launchTester("itoen.oracle.apps.xxccp.xxccp008A01j.server", "XxccpFileUploadAMLocal");
  }


  /**
   * 
   * Container's getter for XxccpLookUpValueVO1
   */
  public XxccpLookUpValueVOImpl getXxccpLookUpValueVO1()
  {
    return (XxccpLookUpValueVOImpl)findViewObject("XxccpLookUpValueVO1");
  }

  /**
   * 
   * Container's getter for XxccpMrpFileUlInterfaceVO1
   */
  public OAViewObjectImpl getXxccpMrpFileUlInterfaceVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxccpMrpFileUlInterfaceVO1");
  }

}