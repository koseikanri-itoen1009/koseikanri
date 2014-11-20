/*============================================================================
* ファイル名 : XxcsoCustomDmlExecUtils
* 概要説明   : カスタムDML実行ユーティリティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.jbo.AttributeDef;
import oracle.jbo.server.EntityDefImpl;
import oracle.sql.Datum;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import java.sql.SQLException;
import java.util.ArrayList;

/*******************************************************************************
 * 自作したDML文を実行するためのクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCustomDmlExecUtils 
{
  /*****************************************************************************
   * INSERT処理です。
   * @param txn       OADBTransactionインスタンス
   * @param tableName INSERTするテーブル名
   * @param entity    INSERT対象のエンティティオブジェクト
   * @param entityDef INSERT対象のエンティティ定義オブジェクト
   * @throws SQLException
   *****************************************************************************
   */
  public static void insertRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
  ) throws SQLException
  {
    insertRow(txn, tableName, entity, entityDef,null);
  }
  
  /*****************************************************************************
   * INSERT処理です。
   * @param txn       OADBTransactionインスタンス
   * @param tableName INSERTするテーブル名
   * @param entity    INSERT対象のエンティティオブジェクト
   * @param entityDef INSERT対象のエンティティ定義オブジェクト
   * @param leaves    INSERTをしない項目のINDEXリスト
   * @throws SQLException
   *****************************************************************************
   */
  public static void insertRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
   ,int[]           leaves
  ) throws SQLException
  {
    XxcsoUtils.debug(txn, "[START]");
    
    StringBuffer sql = new StringBuffer(1000);
    sql.append("INSERT INTO ").append(tableName).append("(");

    AttributeDef[] attrDefs = entityDef.getAttributeDefs();
    int columnIndex   = 0;
    boolean commaFlag = false;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      if ( commaFlag )
      {
        sql.append(",");
      }
      commaFlag = true;
      sql.append(attrDefs[i].getColumnName());
    }
    
    sql.append(")VALUES(");
    commaFlag = false;

    columnIndex = 0;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      if ( commaFlag )
      {
        sql.append(",");
      }
      commaFlag = true;
      sql.append(":").append(columnIndex);
    }
    sql.append(")");
    
    XxcsoUtils.debug(txn, sql.toString());
    
    OracleCallableStatement stmt
      = (OracleCallableStatement)
          txn.createCallableStatement(sql.toString(), 0);

    columnIndex = 0;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      Object object = entity.getAttributeInternal(attrDefs[i].getIndex());
      int sqlType   = attrDefs[i].getSQLType();

      bindObject(txn, stmt, columnIndex, object, sqlType);
    }

    stmt.execute();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * UPDATE処理です。
   * @param txn       OADBTransactionインスタンス
   * @param tableName UPDATEするテーブル名
   * @param entity    UPDATE対象のエンティティオブジェクト
   * @param entityDef UPDATE対象のエンティティ定義オブジェクト
   * @param leaves    UPDATEをしない項目のINDEXリスト
   * @throws SQLException
   *****************************************************************************
   */
  public static void updateRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
  ) throws SQLException
  {
    updateRow(txn, tableName, entity, entityDef, null);
  }
  
  /*****************************************************************************
   * UPDATE処理です。
   * @param txn       OADBTransactionインスタンス
   * @param tableName UPDATEするテーブル名
   * @param entity    UPDATE対象のエンティティオブジェクト
   * @param entityDef UPDATE対象のエンティティ定義オブジェクト
   * @param leaves    UPDATEをしない項目のINDEXリスト
   * @throws SQLException
   *****************************************************************************
   */
  public static void updateRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
   ,int[]           leaves
  ) throws SQLException
  {
    XxcsoUtils.debug(txn, "[START]");
    
    StringBuffer sql = new StringBuffer(1000);
    sql.append("UPDATE ").append(tableName).append(" SET ");

    AttributeDef[] attrDefs = entityDef.getAttributeDefs();
    ArrayList pkAttrDefList = new ArrayList();
    int columnIndex   = 0;
    boolean commaFlag = false;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( attrDefs[i].isPrimaryKey() )
      {
        pkAttrDefList.add(attrDefs[i]);
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      if ( commaFlag )
      {
        sql.append(",");
      }
      commaFlag = true;
      sql.append(attrDefs[i].getColumnName());
      sql.append(" = :");
      sql.append(columnIndex);
    }
    
    sql.append(" WHERE ");
    for ( int i = 0; i < pkAttrDefList.size(); i++ )
    {
      columnIndex++;

      AttributeDef attrDef = (AttributeDef)pkAttrDefList.get(i);
      sql.append(attrDef.getColumnName()).append(" = :");
      sql.append(columnIndex);
    }
    
    XxcsoUtils.debug(txn, sql.toString());
    
    OracleCallableStatement stmt
      = (OracleCallableStatement)
          txn.createCallableStatement(sql.toString(), 0);

    columnIndex = 0;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isQueriable() )
      {
        continue;
      }

      if ( attrDefs[i].isPrimaryKey() )
      {
        continue;
      }

      if ( leaves != null )
      {
        boolean contFlag = false;
        
        for ( int k = 0; k < leaves.length; k++ )
        {
          if ( leaves[k] == attrDefs[i].getIndex() )
          {
            contFlag = true;
            break;
          }
        }

        if ( contFlag )
        {
          continue;
        }
      }
      
      columnIndex++;
      
      Object object = entity.getAttributeInternal(attrDefs[i].getIndex());
      int sqlType   = attrDefs[i].getSQLType();

       bindObject(txn, stmt, columnIndex, object, sqlType);
   }

    for ( int i = 0; i < pkAttrDefList.size(); i++ )
    {
      columnIndex++;

      AttributeDef attrDef = (AttributeDef)pkAttrDefList.get(i);
      Object object = entity.getAttributeInternal(attrDef.getIndex());
      int sqlType = attrDef.getSQLType();

      bindObject(txn, stmt, columnIndex, object, sqlType);
    }

    stmt.execute();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * DELETE処理です。
   * @param txn       OADBTransactionインスタンス
   * @param tableName DELETEするテーブル名
   * @param entity    DELETE対象のエンティティオブジェクト
   * @param entityDef DELETE対象のエンティティ定義オブジェクト
   * @throws SQLException
   *****************************************************************************
   */
  public static void deleteRow(
    OADBTransaction txn
   ,String          tableName
   ,OAEntityImpl    entity
   ,EntityDefImpl   entityDef
  ) throws SQLException
  {
    XxcsoUtils.debug(txn, "[START]");
    
    StringBuffer sql = new StringBuffer(1000);
    sql.append("DELETE ").append(tableName).append(" WHERE ");

    AttributeDef[] attrDefs = entityDef.getAttributeDefs();
    ArrayList pkAttrDefList = new ArrayList();
    int columnIndex = 0;
    boolean andFlag = false;
    
    for ( int i = 0; i < attrDefs.length; i++ )
    {
      if ( ! attrDefs[i].isPrimaryKey() )
      {
        continue;
      }

      pkAttrDefList.add(attrDefs[i]);
      
      columnIndex++;
      
      if ( andFlag )
      {
        sql.append(" AND ");
      }
      andFlag = true;
      sql.append(attrDefs[i].getColumnName());
      sql.append(" = :").append(columnIndex);
    }
    
    XxcsoUtils.debug(txn, sql.toString());
    
    OracleCallableStatement stmt
      = (OracleCallableStatement)
          txn.createCallableStatement(sql.toString(), 0);

    columnIndex = 0;
    
    for ( int i = 0; i < pkAttrDefList.size(); i++ )
    {
      columnIndex++;

      AttributeDef attrDef = (AttributeDef)pkAttrDefList.get(i);
      Object object = entity.getAttributeInternal(attrDef.getIndex());
      int sqlType   = attrDef.getSQLType();

      bindObject(txn, stmt,columnIndex, object, sqlType);
    }

    stmt.execute();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * バインド処理です。
   * @param stmt      OracleCallableStatementインスタンス
   * @param index     バインドする場所
   * @param object    バインドする値
   * @param sqlType   バインドする型
   * @throws SQLException
   *****************************************************************************
   */
  private static void bindObject(
    OADBTransaction         txn
   ,OracleCallableStatement stmt
   ,int                     index
   ,Object                  object
   ,int                     sqlType
  ) throws SQLException
  {
    if ( object == null )
    {
      XxcsoUtils.debug(txn, "bind [" + index + "] = null");
      stmt.setNull(index, sqlType);
    }
    else
    {
      XxcsoUtils.debug(txn, "bind [" + index + "] = " + object.toString());
      if ( object instanceof Datum )
      {
        stmt.setOracleObject(index, (Datum)object);          
      }
      else
      {
        stmt.setObject(index, object, sqlType);
      }
    }    
  }
}